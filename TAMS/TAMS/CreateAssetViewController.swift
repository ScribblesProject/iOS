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
    @IBOutlet var memoPlayButton: UIButton!
    @IBOutlet var memoDeleteButton: UIButton!
    @IBOutlet var assetDescription: UITextView!
    var keyboardShowing = false
    
    var assetLongitude:Double = 0.0
    var assetLatitude:Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assetCategory.text = ""
        assetCategoryDescription = ""
        assetType.text = ""
        assetLocation.text = ""

        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keboardDidHide:", name: UIKeyboardDidHideNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
    
    func didSelectLocations(locations: [CLLocationCoordinate2D]) {
        assetLatitude = locations[0].latitude
        assetLongitude = locations[0].longitude
        assetLocation.text = "\(assetLatitude), \(assetLongitude)"
    }
    
    //MARK: Button Actions
    
    @IBAction func doneButtonPress(sender: AnyObject) {
        
        if !validate() {
            return
        }
        
        let newAsset = formatAsset()
        
        SVProgressHUD.showWithStatus("Creating Asset", maskType: .Black)
        BackendAPI.create(newAsset) { (success) -> Void in
            if success {
                let queue = NSOperationQueue()
                queue.maxConcurrentOperationCount = 1
                queue.addOperationWithBlock({ () -> Void in
                    sleep(2)
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        SVProgressHUD.showWithStatus("Uploading Asset Image", maskType: .Black)
                    })
                })
                queue.addOperationWithBlock({ () -> Void in
                    sleep(2)
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        SVProgressHUD.showWithStatus("Uploading Asset Voice Memo", maskType: .Black)
                    })
                })
                queue.addOperationWithBlock({ () -> Void in
                    sleep(2)
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        SVProgressHUD.showSuccessWithStatus("Asset Created Successfully", maskType: .Black)
                        self.navigationController?.popViewControllerAnimated(true)
                    })
                })
            }
            else {
                SVProgressHUD.showErrorWithStatus("Error Creating Asset")
            }
        }
    }
    @IBAction func addPhotoButtonPress(sender: AnyObject) {
        let alert = UIAlertController(title: "Not Implemented", message: "Coming Soon...", preferredStyle: .Alert)
        let cancelButton = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alert.addAction(cancelButton)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func memoPlayButtonPress(sender: AnyObject) {
        let alert = UIAlertController(title: "Not Implemented", message: "Coming Soon...", preferredStyle: .Alert)
        let cancelButton = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alert.addAction(cancelButton)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func memoDeleteButtonPress(sender: AnyObject) {
        let alert = UIAlertController(title: "Not Implemented", message: "Coming Soon...", preferredStyle: .Alert)
        let cancelButton = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alert.addAction(cancelButton)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //MARK: CategTypeViewControllerProtocol callbacks
    
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
}
