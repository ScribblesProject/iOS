//
//  AssetListViewController.swift
//  TAMS
//
//  Created by Daniel Jackson on 3/16/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit
import SVProgressHUD

class AssetListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var assets = [Asset]()
    @IBOutlet var tableView:UITableView!
    @IBOutlet var editButton: UIBarButtonItem!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    @IBAction func editButtonPressed(sender: AnyObject) {
        if editButton.title == "Edit" {
            self.tableView.setEditing(true, animated: true)
            self.editButton.title = "Done"
        }
        else {
            self.tableView.setEditing(false, animated: true)
            self.editButton.title = "Edit"
        }
    }
    
    func reload() {
        BackendAPI.list { (list) -> Void in
            self.assets = list
            self.tableView.reloadData()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let actionSheet = UIAlertController(title: "Are You Sure?", message: "This will delete your asset", preferredStyle: .ActionSheet)
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            print("Action Canceled")
        }
        actionSheet.addAction(cancelActionButton)
        
        let deleteActionButton: UIAlertAction = UIAlertAction(title: "Delete Asset", style: .Destructive) { action -> Void in
            print("Deleting...")
            let currentAsset = self.assets[indexPath.row]
            SVProgressHUD.showWithStatus("Deleting Asset", maskType: .Black)
            BackendAPI.delete(currentAsset, completion: { (success) -> Void in
                if success {
                    SVProgressHUD.showSuccessWithStatus("Succesfully Deleted Asset", maskType: .Black)
                }
                else {
                    SVProgressHUD.showErrorWithStatus("Failed To Delete Asset", maskType: .Black)
                }
                self.assets.removeAtIndex(indexPath.row)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "reload", userInfo: nil, repeats: false)
            })
        }
        actionSheet.addAction(deleteActionButton)
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let currentAsset = assets[indexPath.row]
        
        var cellIdentifier = "assetBasicCell"
        if currentAsset.imageUrl.characters.count > 0 {
            cellIdentifier = "assetImageCell"
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        
        // Tags are defined in storyboard
        let primaryLabel = cell?.viewWithTag(10) as? UILabel
        let secondaryLabel = cell?.viewWithTag(11) as? UILabel
        let imageView = cell?.viewWithTag(12) as? LazyImageView
        
        primaryLabel?.text = currentAsset.name
        secondaryLabel?.text = currentAsset.description

        imageView?.loadUrl(currentAsset.imageUrl)
        imageView?.layer.borderColor = UIColor.blackColor().CGColor
        imageView?.layer.borderWidth = 1.0
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
