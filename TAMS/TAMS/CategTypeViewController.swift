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
    func didSelectType(_ type:Type)
    func didSelectCategory(_ category:Category)
}

open class CategTypeViewController: UITableViewController {
    
    var viewType:CategTypeViewType = .type
    var delegate:CategTypeViewControllerProtocol?
    var assetTypeList:[Type] = []
    var assetCategoryList:[Category] = []
    
    var typeCategory:Category?
    
    public enum CategTypeViewType {
        case category, type
    }
    
    func setupTypeView(category:Category?, delegate:CategTypeViewControllerProtocol)
    {
        self.viewType = .type
        self.typeCategory =  category
        self.delegate = delegate
    }
    
    func setupCategoryView(delegate:CategTypeViewControllerProtocol)
    {
        viewType = .category
        self.delegate = delegate
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewType == .type {
            setupTypes(category: typeCategory)
        }
        else if viewType == .category {
            setupCategories()
        }
    }
    
    open func setupCategories()
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
    
    open func setupTypes(category:Category?)
    {
        self.title = "Select Type"
        
        if category == nil {
            return
        }
        
        BackendAPI.typeList(category: category!) { (types) -> Void in
            self.assetTypeList = types
            self.assetCategoryList = []
            self.tableView.reloadData()
        }
    }
    
    func presentError(_ message:String) {
        DispatchQueue.main.async { () -> Void in
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func addButtonPressed(_ sender: AnyObject) {
        
        var alert:UIAlertController
        
        var typeName = "Type"
        if viewType == .category {
            typeName = "Category"
        }
        alert = UIAlertController(title: "Create \(typeName)", message: "", preferredStyle: .alert)
        
        //Add Name Field
        alert.addTextField { (textField) -> Void in
            textField.placeholder = "Name"
        }
        
        //Add Description Field
        if viewType == .category {
            alert.addTextField { (textField) -> Void in
                textField.placeholder = "Description"
            }
        }
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelButton)
        
        //Add Ok Button with handler.
        let okButton = UIAlertAction(title: "Ok", style: .default) { (okAction) -> Void in
            let nameField = alert.textFields!.first!
            
            switch self.viewType {
            case .category:
                let descField = alert.textFields!.last!
                if nameField.text?.characters.count ?? 0 == 0 || descField.text?.characters.count ?? 0 == 0 {
                    self.presentError("Please fill in both name and description")
                    return;
                }
                let newCateg = Category(id: 0, name: nameField.text ?? "", description: descField.text ?? "")
                self.delegate?.didSelectCategory(newCateg)
                _ = self.navigationController?.popViewController(animated: true)
                
            case .type:
                if nameField.text?.characters.count ?? 0 == 0 {
                    self.presentError("Please fill in name")
                    return
                }
                let newType = Type(id: 0, name: nameField.text ?? "")
                self.delegate?.didSelectType(newType)
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
    
//MARK: Table View Data Source
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewType {
        case .category:
            return self.assetCategoryList.count
        case .type:
            return self.assetTypeList.count
        }
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell")!
        
        switch viewType {
        case .category:
            let currentCateg = assetCategoryList[(indexPath as NSIndexPath).row]
            cell.textLabel?.text = currentCateg.name
            cell.detailTextLabel?.text = currentCateg.description
            
        case .type:
            let currentType = assetTypeList[(indexPath as NSIndexPath).row]
            cell.textLabel?.text = currentType.name
            cell.detailTextLabel?.text = ""
        }
        
        return cell
    }
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewType {
        case .category:
            let currentCateg = assetCategoryList[(indexPath as NSIndexPath).row]
            delegate?.didSelectCategory(currentCateg)
            _ = self.navigationController?.popViewController(animated: true)
            
        case .type:
            let currentType = assetTypeList[(indexPath as NSIndexPath).row]
            delegate?.didSelectType(currentType)
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
}
