//
//  CreateAssetViewController.swift
//  TAMS
//
//  Created by Daniel Jackson on 3/17/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit
import SVProgressHUD
import Alamofire
import MapKit

class CreateAssetViewController: UITableViewController, CategTypeViewControllerProtocol, MapViewControllerProtocol {
    
    var updateAsset:Asset?
    
    @IBOutlet var addPhotoButton: UIButton!
    @IBOutlet var assetPhoto: UIImageView!
    @IBOutlet var assetName: UITextField!
    @IBOutlet var assetCategory: UILabel!
    @IBOutlet var assetType: UILabel!
    @IBOutlet var assetLocation: UILabel!
    @IBOutlet var assetDescription: UITextView!
    @IBOutlet var memoRecordButton: UIButton!
    @IBOutlet var memoPlayButton: UIButton!
    @IBOutlet var memoDeleteButton: UIButton!
    @IBOutlet var memoProgressSlider: UISlider!
    var keyboardShowing = false
    
    var assetCategoryObject:Category?
    var locations:[Int:Asset.LocationType] = [:]
    var assetImage:UIImage?
    var assetMemoURL:URL?
    
    typealias createAssetCompletionHandler = ((_ success:Bool, _ imageUploaded:Bool, _ memoUploaded:Bool)->Void)
    
    //MARK: -
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if updateAsset == nil {
            setupView()
        }
        else {
            setupViewForUpdate()
        }

        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(CreateAssetViewController.keboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CreateAssetViewController.keboardDidHide(_:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }
    
    func prepareUpdate(asset:Asset)
    {
        updateAsset = asset
    }
    
    func setupViewForUpdate()
    {
        //Recorder
        memoPlayButton.isHidden = true
        memoDeleteButton.isHidden = true
        memoProgressSlider.isHidden = true
        
        if let asset = updateAsset {
            assetName.text = asset.name
            assetCategory.text = asset.category.name
            assetType.text = asset.type
            assetDescription.text = asset.description
            
            if asset.locations.count > 0 {
                assetLocation.text = "\(asset.locations.count) selected"
            }
            
            locations = asset.locations
            assetCategoryObject = asset.category
            
            if asset.voiceUrl.characters.count == 0 {
                //Recorder
                memoRecordButton.isHidden = true
                memoPlayButton.isHidden = false
                memoDeleteButton.isHidden = false
                memoProgressSlider.isHidden = false
            }
            
            //Load Image
            let imageUrl = asset.imageUrl
            Alamofire.request(imageUrl, method:.get).validate().response { response in
                if let data = response.data {
                    let image = UIImage(data: data)
                    self.assetPhoto.image = image
                }
            }
        }
        else {
             _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    func setupView()
    {
        assetCategory.text = ""
        assetType.text = ""
        assetLocation.text = ""
        
        //Recorder
        memoPlayButton.isHidden = true
        memoDeleteButton.isHidden = true
        memoProgressSlider.isHidden = true
    }
    
    func keboardDidShow(_ notification:Notification) {
        keyboardShowing = true
    }
    
    func keboardDidHide(_ notification:Notification) {
        keyboardShowing = false
    }

    func formatAsset()->Asset
    {
        let imageUrl = updateAsset?.imageUrl ?? ""
        var voiceUrl = updateAsset?.voiceUrl ?? ""
        if assetMemoURL != nil {
            voiceUrl = ""
        }
        
        let category = Category(id: (updateAsset?.category.id ?? NSNumber(value:0)),
                                name: assetCategory.text ?? "",
                                description: assetCategoryObject?.description ?? "")
        
        let asset = Asset(id: (updateAsset?.id ?? NSNumber(value:0)),
                          name: assetName.text ?? "",
                          description: assetDescription.text ?? "",
                          type: assetType.text ?? "",
                          category: category,
                          imageUrl: imageUrl,
                          voiceUrl: voiceUrl,
                          locations: self.locations)
        
        return asset
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination
        
        switch segue.identifier ?? "" {
        case "pushSelectCategory":
            (destination as! CategTypeViewController).setupCategoryView(delegate: self)
        case "pushSelectType":
            (destination as! CategTypeViewController).setupTypeView(category: assetCategoryObject, delegate: self)
        case "pushSelectLocation":
            (destination as! MapViewController).setup(.select, delegate: self)
        default:
            break
        }
    }
    
    //MARK: -
    //MARK: Button Actions
    
    @IBAction func doneButtonPress(_ sender: AnyObject) {
        
        if !validate() {
            return
        }
        
        let newAsset = formatAsset()
        
        updateCreateAsset(newAsset) { (success, imageUploaded, memoUploaded) -> Void in
            if success {
                DispatchQueue.main.async(execute: { () -> Void in
                    SVProgressHUD.showSuccess(withStatus: "Successfully Created Asset!")
                    Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(CreateAssetViewController.popView), userInfo: nil, repeats: false)
                })
            }
            else {
                DispatchQueue.main.async(execute: { () -> Void in
                    SVProgressHUD.showError(withStatus: "Failed To Created Asset!")
                    sleep(2)
                    _ = self.navigationController?.popViewController(animated: true)
                    Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(CreateAssetViewController.popView), userInfo: nil, repeats: false)
                })
            }
        }
    }
    
    func popView()
    {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func updateCreateAsset(_ asset:Asset, completion:@escaping createAssetCompletionHandler) {
        DispatchQueue.main.async(execute: { () -> Void in
            SVProgressHUD.show(withStatus: "Creating Asset")
        })
        
        //do this after asset update/creation
        let assetCreatedBlock:((Bool, NSNumber) -> Void) = { (success, assetId) -> Void in
            if success {
                self.uploadMedia(assetId, completion: completion)
            }
            else {
                completion(false, false, false)
            }
        }
        
        //Perform Create/Update
        if self.updateAsset == nil {
            BackendAPI.create(asset, completion: assetCreatedBlock)
        }
        else {
            DispatchQueue.main.async(execute: { () -> Void in
                //UPDATE
                SVProgressHUD.showError(withStatus: "NOT IMPLEMENTED")
            })
        }
    }
    
    
    func uploadMedia(_ assetId:NSNumber, completion:@escaping createAssetCompletionHandler)
    {
        if let img = self.assetImage {
            //Upload Image
            DispatchQueue.main.async(execute: { () -> Void in
                SVProgressHUD.show(withStatus: "Uploading Asset Image")
            })
            BackendAPI.uploadImage(img, assetId: assetId, progress: { (percent) -> Void in
            }, completion: { (success) -> Void in
                if success {
                    self.uploadMediaMemo(assetId, imageUploaded: true, completion: completion)
                }
                else {
                    self.uploadMediaMemo(assetId, imageUploaded: false, completion: completion)
                }
            })
        }
        else {
            self.uploadMediaMemo(assetId, imageUploaded: false, completion: completion)
        }
    }
    
    
    func uploadMediaMemo(_ assetId:NSNumber, imageUploaded:Bool, completion:@escaping createAssetCompletionHandler) {
        if let fileUrl = assetMemoURL {
            DispatchQueue.main.async(execute: { () -> Void in
                SVProgressHUD.show(withStatus: "Uploading Asset Memo")
            })
            BackendAPI.uploadMemo(fileUrl, assetId: assetId, progress: { (percent) -> Void in
            }, completion: { (success) -> Void in
                if success {
                    completion(true, imageUploaded, true)
                }
                else {
                    completion(true, imageUploaded, false)
                }
            })
        }
        else {
            completion(true, imageUploaded, false)
        }
    }
    
    
    func validate()->Bool {
        let nameCount = assetName.text?.characters.count ?? 0
        let descCount = assetDescription.text.characters.count
        let typeCount = assetType.text?.characters.count ?? 0
        let categCount = assetCategory.text?.characters.count ?? 0
        let valid = (nameCount > 0 && descCount > 0 && typeCount > 0 && categCount > 0)
        
        if !valid {
            let alert = UIAlertController(title: "Uh Oh!", message: "Required fields: Name, Description, Category, Type", preferredStyle: .alert)
            let cancelButton = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            alert.addAction(cancelButton)
            self.present(alert, animated: true, completion: nil)
        }
        
        return valid
    }
    
    
    @IBAction func addPhotoButtonPress(_ sender: AnyObject) {
        PhotoPicker.sharedInstance().requestPhoto(viewController: self) { (image) -> Void in
            print("Got Image!!")
            self.assetImage = image
            self.assetPhoto.image = image
            (sender as? UIButton)?.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        }
    }
    
    
    @IBAction func memoRecordButtonPress(_ sender: AnyObject) {
        if VoiceMemoRecorder.sharedInstance().recording {
            let fileURL = VoiceMemoRecorder.sharedInstance().stopRecorder()
            assetMemoURL = fileURL as URL
            
            self.memoRecordButton.isHidden = true
            self.memoRecordButton.setImage(UIImage(named: "record.png"), for: UIControlState())
            self.memoRecordButton.titleLabel?.text = "Record Voice Memo"
            self.memoPlayButton.isHidden = false
            self.memoDeleteButton.isHidden = false
            self.memoProgressSlider.isHidden = false
        }
        else {
            VoiceMemoRecorder.sharedInstance().recordAudio { (success) -> Void in
                if success {
                    //recording...
                    self.memoRecordButton.setImage(UIImage(named: "stop.png"), for: UIControlState())
                    self.memoRecordButton.titleLabel?.text = "Stop Recording"
                }
                else {
                    self.presentError("Could not start recording. Check your phones settings to ensure this application has proper permissions.")
                }
            }
        }
    }
    
    @IBAction func memoPlayButtonPress(_ sender: AnyObject) {
        if VoiceMemoRecorder.sharedInstance().playing()
        {
            VoiceMemoRecorder.sharedInstance().pause()
        }
        else {
            self.memoProgressSlider.maximumValue = 1.0
            VoiceMemoRecorder.sharedInstance().play({ (progress, playing, finished) -> Void in
                if !playing || finished {
                    self.memoPlayButton.setImage(UIImage(named: "play.png"), for: UIControlState())
                }
                else {
                    self.memoPlayButton.setImage(UIImage(named: "pause.png"), for: UIControlState())
                }
                
                if finished {
                    self.memoProgressSlider.value = 1.0
                }
                else {
                    self.memoProgressSlider.value = Float(progress)
                }
                
                print("Progress: \(self.memoProgressSlider.value)")
            })
        }
    }
    
    @IBAction func memoDeleteButtonPress(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Are You Sure?", message: "This will erase your current recording. This action is not recoverable.", preferredStyle: .alert)
        let cancelButton = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        let deleteButton = UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive) { (action) -> Void in
            VoiceMemoRecorder.sharedInstance().deleteRecording()
            self.memoProgressSlider.value = 0.0
            self.memoPlayButton.isHidden = true
            self.memoDeleteButton.isHidden = true
            self.memoProgressSlider.isHidden = true
            self.memoRecordButton.isHidden = false
        }
        alert.addAction(cancelButton)
        alert.addAction(deleteButton)
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: -
    //MARK: Field Callbacks
    
    func didSelectLocations(_ locations: [CLLocationCoordinate2D]) {
        
        if locations.count == 0 {
            return
        }
        
        var order = 0
        for loc in locations {
            order += 1
            self.locations[order] = Asset.LocationType(latitude: loc.latitude, longitude: loc.longitude)
        }
        
        assetLocation.text = "\(locations.count) selected"
    }
    
    func didSelectType(_ type:Type) {
        assetType.text = type.name
    }
    
    func didSelectCategory(_ category:Category) {
        print("didSelectCategory with name: \(category)")
        assetCategory.text = category.name
        assetCategoryObject = category
        assetType.text = ""
    }
    
    //MARK: -
    //MARK: Table View Delegate
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if keyboardShowing {
            //Dismiss keyboard on scroll
            assetName.resignFirstResponder()
            assetDescription.resignFirstResponder()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - 
    
    func presentError(_ message:String) {
        DispatchQueue.main.async { () -> Void in
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
