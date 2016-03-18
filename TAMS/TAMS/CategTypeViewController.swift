//
//  CategTypeViewController.swift
//  TAMS
//
//  Created by Daniel Jackson on 3/17/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit
import SVProgressHUD

public protocol CategTypeViewControllerProtocol {
    func didSelectType(type:Type)
    func didSelectCategory(category:Category)
}

public class CategTypeViewController: UITableViewController {
    
    var viewType:CategTypeViewType = .Type
    var delegate:CategTypeViewControllerProtocol?
    var assetTypeList:[Type] = []
    var assetCategoryList:[Category] = []
    
    public enum CategTypeViewType {
        case Category, Type
    }
    
    public func setup(viewType vt:CategTypeViewType, delegate del:CategTypeViewControllerProtocol)
    {
        viewType = vt
        delegate = del
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewType == .Type {
            setupTypes()
        }
        else if viewType == .Category {
            setupCategories()
        }
    }
    
    public func setupCategories()
    {
        self.title = "Select Category"
//        SVProgressHUD.showWithStatus("Loading..", maskType: .Black)
        BackendAPI.categoryList { (categories) -> Void in
            self.assetCategoryList = categories
            self.assetTypeList = []
            self.tableView.reloadData()
//            SVProgressHUD.dismiss()
        }
    }
    
    public func setupTypes()
    {
        self.title = "Select Type"
        BackendAPI.typeList { (types) -> Void in
            self.assetTypeList = types
            self.assetCategoryList = []
            self.tableView.reloadData()
        }
    }
    
    func presentError(message:String) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func addButtonPressed(sender: AnyObject) {
        
        var alert:UIAlertController
        
        var typeName = "Type"
        if viewType == .Category {
            typeName = "Category"
        }
        alert = UIAlertController(title: "Create \(typeName)", message: "", preferredStyle: .Alert)
        
        //Add Name Field
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Name"
        }
        
        //Add Description Field
        if viewType == .Category {
            alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
                textField.placeholder = "Description"
            }
        }
        
        //Add Ok Button with handler.
        let okButton = UIAlertAction(title: "Ok", style: .Default) { (okAction) -> Void in
            let nameField = alert.textFields!.first!
            
            switch self.viewType {
            case .Category:
                let descField = alert.textFields!.last!
                if nameField.text?.characters.count ?? 0 == 0 || descField.text?.characters.count ?? 0 == 0 {
                    self.presentError("Please fill in both name and description")
                    return;
                }
                let newCateg = Category(id: 0, name: nameField.text ?? "", description: descField.text ?? "")
                self.delegate?.didSelectCategory(newCateg)
                self.navigationController?.popViewControllerAnimated(true)
                
            case .Type:
                if nameField.text?.characters.count ?? 0 == 0 {
                    self.presentError("Please fill in name")
                    return
                }
                let newType = Type(id: 0, name: nameField.text ?? "")
                self.delegate?.didSelectType(newType)
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
        alert.addAction(okButton)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
//MARK: Table View Data Source
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewType {
        case .Category:
            return self.assetCategoryList.count
        case .Type:
            return self.assetTypeList.count
        }
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("basicCell")!
        
        switch viewType {
        case .Category:
            let currentCateg = assetCategoryList[indexPath.row]
            cell.textLabel?.text = currentCateg.name
            cell.detailTextLabel?.text = currentCateg.description
            
        case .Type:
            let currentType = assetTypeList[indexPath.row]
            cell.textLabel?.text = currentType.name
            cell.detailTextLabel?.text = ""
        }
        
        return cell
    }
    
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch viewType {
        case .Category:
            let currentCateg = assetCategoryList[indexPath.row]
            delegate?.didSelectCategory(currentCateg)
            self.navigationController?.popViewControllerAnimated(true)
            
        case .Type:
            let currentType = assetTypeList[indexPath.row]
            delegate?.didSelectType(currentType)
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
}
