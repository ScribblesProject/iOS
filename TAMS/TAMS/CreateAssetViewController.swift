//
//  CreateAssetViewController.swift
//  TAMS
//
//  Created by Daniel Jackson on 3/17/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit
import SVProgressHUD
import MapKit

class CreateAssetViewController: UITableViewController, CategTypeViewControllerProtocol, MapViewControllerProtocol {
    
    @IBOutlet var addPhotoButton: UIButton!
    @IBOutlet var assetPhoto: UIImageView!
    @IBOutlet var assetName: UITextField!
    @IBOutlet var assetCategory: UILabel!
    var assetCategoryDescription:String = ""
    @IBOutlet var assetType: UILabel!
    @IBOutlet var assetLocation: UILabel!
    @IBOutlet var memoRecordButton: UIButton!
    @IBOutlet var memoPlayButton: UIButton!
    @IBOutlet var memoDeleteButton: UIButton!
    @IBOutlet var memoProgressSlider: UISlider!
    @IBOutlet var assetDescription: UITextView!
    var keyboardShowing = false
    
    var assetLongitude:Double = 0.0
    var assetLatitude:Double = 0.0
    var assetImage:UIImage?
    var assetMemoURL:NSURL?
    
    //MARK: -
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()

        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keboardDidHide:", name: UIKeyboardDidHideNotification, object: nil)
    }
    
    func setupView()
    {
        assetCategory.text = ""
        assetCategoryDescription = ""
        assetType.text = ""
        assetLocation.text = ""
        
        //Recorder
        memoPlayButton.hidden = true
        memoDeleteButton.hidden = true
        memoProgressSlider.hidden = true
    }
    
    func keboardDidShow(notification:NSNotification) {
        keyboardShowing = true
    }
    
    func keboardDidHide(notification:NSNotification) {
        keyboardShowing = false
    }

    func formatAsset()->Asset
    {
        return Asset(
            id: -1,
            name: assetName.text ?? "",
            description: assetDescription.text ?? "",
            type: assetType.text ?? "",
            category: assetCategory.text ?? "",
            category_description: assetCategoryDescription,
            imageUrl: "",
            voiceUrl: "",
            latitude: assetLatitude,
            longitude: assetLongitude
        )
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController
        
        switch segue.identifier ?? "" {
        case "pushSelectCategory":
            (destination as! CategTypeViewController).setup(viewType: .Category, delegate: self)
        case "pushSelectType":
            (destination as! CategTypeViewController).setup(viewType: .Type, delegate: self)
        case "pushSelectLocation":
            (destination as! MapViewController).setup(.Select, delegate: self)
        default:
            break
        }
    }
    
    //MARK: Button Actions
    
    @IBAction func doneButtonPress(sender: AnyObject) {
        
        if !validate() {
            return
        }
        
        let newAsset = formatAsset()
        
        createAsset(newAsset) { (success, imageUploaded, memoUploaded) -> Void in
            if success {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SVProgressHUD.showSuccessWithStatus("Successfully Created Asset!", maskType: .Black)
                    NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "popView", userInfo: nil, repeats: false)
                })
            }
            else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SVProgressHUD.showErrorWithStatus("Failed To Created Asset!", maskType: .Black)
                    sleep(2)
                    self.navigationController?.popViewControllerAnimated(true)
                    NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "popView", userInfo: nil, repeats: false)
                })
            }
        }
    }
    
    func popView()
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    typealias createAssetCompletionHandler = ((success:Bool, imageUploaded:Bool, memoUploaded:Bool)->Void)
    
    func createAsset(asset:Asset, completion:createAssetCompletionHandler) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            SVProgressHUD.showWithStatus("Creating Asset", maskType: .Black)
        })
        BackendAPI.create(asset) { (success, assetId) -> Void in
            if success {
                self.uploadMedia(assetId, completion: completion)
            }
            else {
                completion(success: false, imageUploaded: false, memoUploaded: false)
            }
        }
    }
    
    func uploadMedia(assetId:Int, completion:createAssetCompletionHandler)
    {
        if let img = self.assetImage {
            //Upload Image
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                SVProgressHUD.showWithStatus("Uploading Asset Image", maskType: .Black)
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
    
    func uploadMediaMemo(assetId:Int, imageUploaded:Bool, completion:createAssetCompletionHandler) {
        if let fileUrl = assetMemoURL {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                SVProgressHUD.showWithStatus("Uploading Asset Memo", maskType: .Black)
            })
            BackendAPI.uploadMemo(fileUrl, assetId: assetId, progress: { (percent) -> Void in
            }, completion: { (success) -> Void in
                if success {
                    completion(success: true, imageUploaded: imageUploaded, memoUploaded: true)
                }
                else {
                    completion(success: true, imageUploaded: imageUploaded, memoUploaded: false)
                }
            })
        }
        else {
            completion(success: true, imageUploaded: imageUploaded, memoUploaded: false)
        }
    }
    
    func validate()->Bool {
        let nameCount = assetName.text?.characters.count ?? 0
        let descCount = assetDescription.text.characters.count
        let typeCount = assetType.text?.characters.count ?? 0
        let categCount = assetCategory.text?.characters.count ?? 0
        let valid = (nameCount > 0 && descCount > 0 && typeCount > 0 && categCount > 0)
        
        if !valid {
            let alert = UIAlertController(title: "Uh Oh!", message: "Required fields: Name, Description, Category, Type", preferredStyle: .Alert)
            let cancelButton = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
            alert.addAction(cancelButton)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        return valid
    }
    
    @IBAction func addPhotoButtonPress(sender: AnyObject) {
        PhotoPicker.sharedInstance().requestPhoto(viewController: self) { (image) -> Void in
            print("Got Image!!")
            self.assetImage = image
            self.assetPhoto.image = image
            (sender as? UIButton)?.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        }
    }
    
    @IBAction func memoRecordButtonPress(sender: AnyObject) {
        if VoiceMemoRecorder.sharedInstance().recording {
            let fileURL = VoiceMemoRecorder.sharedInstance().stopRecorder()
            assetMemoURL = fileURL
            
            self.memoRecordButton.hidden = true
            self.memoRecordButton.setImage(UIImage(named: "record.png"), forState: .Normal)
            self.memoRecordButton.titleLabel?.text = "Record Voice Memo"
            self.memoPlayButton.hidden = false
            self.memoDeleteButton.hidden = false
            self.memoProgressSlider.hidden = false
        }
        else {
            VoiceMemoRecorder.sharedInstance().recordAudio { (success) -> Void in
                if success {
                    //recording...
                    self.memoRecordButton.setImage(UIImage(named: "stop.png"), forState: .Normal)
                    self.memoRecordButton.titleLabel?.text = "Stop Recording"
                }
                else {
                    self.presentError("Could not start recording. Check your phones settings to ensure this application has proper permissions.")
                }
            }
        }
    }
    
    @IBAction func memoPlayButtonPress(sender: AnyObject) {
        if VoiceMemoRecorder.sharedInstance().playing()
        {
            VoiceMemoRecorder.sharedInstance().pause()
        }
        else {
            self.memoProgressSlider.maximumValue = 1.0
            VoiceMemoRecorder.sharedInstance().play({ (progress, playing, finished) -> Void in
                if !playing || finished {
                    self.memoPlayButton.setImage(UIImage(named: "play.png"), forState: .Normal)
                }
                else {
                    self.memoPlayButton.setImage(UIImage(named: "pause.png"), forState: .Normal)
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
    
    @IBAction func memoDeleteButtonPress(sender: AnyObject) {
        let alert = UIAlertController(title: "Are You Sure?", message: "This will erase your current recording. This action is not recoverable.", preferredStyle: .Alert)
        let cancelButton = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        let deleteButton = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive) { (action) -> Void in
            VoiceMemoRecorder.sharedInstance().deleteRecording()
            self.memoProgressSlider.value = 0.0
            self.memoPlayButton.hidden = true
            self.memoDeleteButton.hidden = true
            self.memoProgressSlider.hidden = true
            self.memoRecordButton.hidden = false
        }
        alert.addAction(cancelButton)
        alert.addAction(deleteButton)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //MARK: Field Callbacks
    
    func didSelectLocations(locations: [CLLocationCoordinate2D]) {
        
        if locations.count == 0 {
            return
        }
        
        assetLatitude = locations[0].latitude
        assetLongitude = locations[0].longitude
        assetLocation.text = String(format: "%.5f, %.5f", arguments: [assetLatitude,assetLongitude])
    }
    
    func didSelectType(type:Type) {
        assetType.text = type.name
    }
    
    func didSelectCategory(category:Category) {
        print("didSelectCategory with name: \(category)")
        assetCategory.text = category.name
        assetCategoryDescription = category.description
    }
    
    //MARK: Table View Delegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if keyboardShowing {
            //Dismiss keyboard on scroll
            assetName.resignFirstResponder()
            assetDescription.resignFirstResponder()
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    //MARK: - 
    
    func presentError(message:String) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}
