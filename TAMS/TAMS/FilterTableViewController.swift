//
//  FilterTableViewController.swift
//  TAMS
//
//  Created by Daniel Jackson on 10/1/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit

class FilterTableViewController: UITableViewController {
    
    typealias ApplyHandlerBlock = ((Category?, Type?) -> Void)
    var selectedCategory:Category?
    var selectedType:Type?
    var applyHandler:ApplyHandlerBlock?
    
    func prepareView(category:Category?, type:Type?, applyHandler:@escaping ApplyHandlerBlock)
    {
        self.selectedCategory = category
        self.selectedType = type
        self.applyHandler = applyHandler
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func clearButton(_ sender: AnyObject) {
        selectedType = nil
        selectedCategory = nil
        self.tableView.reloadData()
    }
    
    @IBAction func applyButton(_ sender: AnyObject) {
        self.applyHandler?(selectedCategory, selectedType)
        
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Table view data source

    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row
        {
        case 0:
            return createCategoryCell()
        case 1:
            return createTypeCell()
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            performCategorySelection()
            break
        case 1:
            performTypeSelection()
            break
        default:
            break
        }
    }
    
    func createCategoryCell() -> UITableViewCell
    {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: #function)
        
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = "Asset Category"
        cell.detailTextLabel?.text = selectedCategory?.name ?? ""
        
        return cell
    }

    func createTypeCell() -> UITableViewCell
    {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: #function)
        
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = "Asset Type"
        cell.detailTextLabel?.text = selectedType?.name ?? ""
        
        if selectedCategory == nil
        {
            cell.selectionStyle = .none
            cell.textLabel?.textColor = UIColor.gray
        }
        else {
            cell.textLabel?.textColor = UIColor.black
        }
        
        return cell
    }
    
    func performCategorySelection()
    {
        self.performSegue(withIdentifier: "presentCategoryFilter", sender: self)
    }
    
    func performTypeSelection()
    {
        if selectedCategory == nil
        {
            alert(title: "Alert", message: "Must select category first.", handler: nil)
            return
        }
        
        self.performSegue(withIdentifier: "presentTypeFilter", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "presentTypeFilter"
        {
            let destination = segue.destination as! FilterTypeTableViewController
            
            destination.prepareView(category: selectedCategory!, selectionHandler: { (type) in
                self.selectedType = type
                self.tableView.reloadData()
            })
        }
        else if segue.identifier == "presentCategoryFilter"
        {
            let destination = segue.destination as! FilterCategoryTableViewController
            
            destination.prepareView(selectionHandler: { (category) in
                self.selectedCategory = category
                self.tableView.reloadData()
            })
        }
    }
    
    func alert(title:String, message:String, handler:(()->Void)?)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            handler?()
        }))
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}




