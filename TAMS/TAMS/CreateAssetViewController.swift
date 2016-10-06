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
    
    var assetImageModified:Bool {
        get { return (assetImage != nil) }
    }
    var assetMemoModified:Bool {
        get { return (assetMemoURL != nil) }
    }
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
        hideMemoPlayer()
        
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
            
            if asset.voiceUrl.characters.count != 0 {
                showMemoPlayer()
            }
            else {
                hideMemoPlayer()
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
        hideMemoPlayer()
    }
    
    func showMemoPlayer()
    {
        memoRecordButton.isHidden = true
        memoPlayButton.isHidden = false
        memoDeleteButton.isHidden = false
        memoProgressSlider.isHidden = false
    }
    
    func hideMemoPlayer()
    {
        memoRecordButton.isHidden = false
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
            break
        case "pushSelectType":
            (destination as! CategTypeViewController).setupTypeView(category: assetCategoryObject, delegate: self)
            break
        case "pushSelectLocation":
            (destination as! MapViewController).setupAssetSelect(locations:self.locations, delegate: self)
            break
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
        if self.updateAsset == nil
        {
            BackendAPI.create(asset, completion: assetCreatedBlock)
        }
        else if let oldAsset = self.updateAsset
        {
            if oldAsset.differsFrom(asset: asset) {
                BackendAPI.update(asset, completion: { (success) in
                    assetCreatedBlock(success, asset.id)
                })
            }
            else {
                assetCreatedBlock(true, oldAsset.id)
            }
        }
    }
    
    
    func uploadMedia(_ assetId:NSNumber, completion:@escaping createAssetCompletionHandler)
    {
        //No difference between update/create here
        
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
    
    
    func uploadMediaMemo(_ assetId:NSNumber, imageUploaded:Bool, completion:@escaping createAssetCompletionHandler)
    {
        //No difference between update/create here
        
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
            
            self.memoRecordButton.setImage(UIImage(named: "record.png"), for: UIControlState())
            self.memoRecordButton.titleLabel?.text = "Record Voice Memo"
            showMemoPlayer()
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
        if MemoPlayer.shared.playing
        {
            //Pause Pressed
            MemoPlayer.shared.pause()
        }
        else {
            //Play Pressed
            self.memoProgressSlider.maximumValue = 1.0
            
            if assetMemoURL == nil && self.updateAsset?.voiceUrl.characters.count ?? 0 == 0 {
                presentError("Playback Error.")
                hideMemoPlayer()
                return
            }
            
            if assetMemoURL == nil
            {
                let url = self.updateAsset!.voiceUrl
                MemoPlayer.shared.play(remoteUrl:url, { (progress, state, error) -> Void in
                    self.handlePlaybackChange(progress: progress, state:state, error: error)
                })
                return
            }
            
            MemoPlayer.shared.play(localUrl:assetMemoURL!, { (progress, state, error) -> Void in
                self.handlePlaybackChange(progress: progress, state:state, error: error)
            })
        }
    }
    
    func handlePlaybackChange(progress:Double, state:MemoPlayer.MemoPlayerState, error:Error?)
    {
        print("Playback State: " + state.description())
        
        if state != .Playing {
            self.memoPlayButton.setImage(UIImage(named: "play.png"), for: UIControlState())
        }
        else {
            self.memoPlayButton.setImage(UIImage(named: "pause.png"), for: UIControlState())
        }
        
        if state == .Finished {
            self.memoProgressSlider.value = 1.0
        }
        else if state == .Loading || state == .Unknown {
            self.memoProgressSlider.value = 0.0
        }
        else {
            self.memoProgressSlider.value = Float(progress)
        }
        
        print("Progress: \(self.memoProgressSlider.value)")
    }
    
    @IBAction func memoDeleteButtonPress(_ sender: AnyObject) {
        var message:String
        if assetMemoURL == nil {
            message = "This will erase your current recording.\n\nNote: Since this memo is stored on the server, changes wont take affect until you save."
        }
        else {
            message = "This will erase your current recording. This action is not recoverable."
        }
        
        let alert = UIAlertController(title: "Are You Sure?", message: message, preferredStyle: .alert)
        let cancelButton = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        let deleteButton = UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive) { (action) -> Void in
            VoiceMemoRecorder.sharedInstance().deleteRecording()
            self.memoProgressSlider.value = 0.0
            self.hideMemoPlayer()
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
        
        self.locations = [:]
        
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
