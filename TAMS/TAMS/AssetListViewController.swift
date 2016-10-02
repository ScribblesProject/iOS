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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    @IBAction func editButtonPressed(_ sender: AnyObject) {
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let actionSheet = UIAlertController(title: "Are You Sure?", message: "This will delete your asset", preferredStyle: .actionSheet)
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Action Canceled")
        }
        actionSheet.addAction(cancelActionButton)
        
        let deleteActionButton: UIAlertAction = UIAlertAction(title: "Delete Asset", style: .destructive) { action -> Void in
            print("Deleting...")
            let currentAsset = self.assets[(indexPath as NSIndexPath).row]
            SVProgressHUD.show(withStatus: "Deleting Asset")
            BackendAPI.delete(currentAsset, completion: { (success) -> Void in
                if success {
                    SVProgressHUD.showSuccess(withStatus: "Succesfully Deleted Asset")
                }
                else {
                    SVProgressHUD.showError(withStatus: "Failed To Delete Asset")
                }
                self.assets.remove(at: (indexPath as NSIndexPath).row)
                self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.reload), userInfo: nil, repeats: false)
            })
        }
        actionSheet.addAction(deleteActionButton)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let currentAsset = assets[(indexPath as NSIndexPath).row]
        
        var cellIdentifier = "assetBasicCell"
        if currentAsset.imageUrl.characters.count > 0 {
            cellIdentifier = "assetImageCell"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        // Tags are defined in storyboard
        let primaryLabel = cell?.viewWithTag(10) as? UILabel
        let secondaryLabel = cell?.viewWithTag(11) as? UILabel
        let imageView = cell?.viewWithTag(12) as? LazyImageView
        
        primaryLabel?.text = currentAsset.name
        secondaryLabel?.text = currentAsset.description

        imageView?.image = UIImage()
        imageView?.loadUrl(currentAsset.imageUrl)
        imageView?.layer.borderColor = UIColor.black.cgColor
        imageView?.layer.borderWidth = 1.0
        
        return cell!
    }
    
    var selectedIndexPath:IndexPath?
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //nillified after prepare(for segue:,sender:)
        self.selectedIndexPath = indexPath
        
        self.performSegue(withIdentifier: "updateCreateAsset", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "updateCreateAsset" && selectedIndexPath != nil
        {
            let destination = segue.destination as! CreateAssetViewController
            
            let asset = assets[selectedIndexPath!.row]
            destination.prepareUpdate(asset: asset)
            
            selectedIndexPath = nil
        }
    }
}
