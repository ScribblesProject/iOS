//
//  FilterTypeTableViewController.swift
//  TAMS
//
//  Created by Daniel Jackson on 10/1/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit

class FilterTypeTableViewController: UITableViewController {

    typealias FilterTypeSelectionBlock = ((Type) -> Void)
    var category:Category!
    var selectionHandler:FilterTypeSelectionBlock?
    var types:[Type] = []
    
    func prepareView(category:Category, selectionHandler:@escaping FilterTypeSelectionBlock)
    {
        self.category = category
        self.selectionHandler = selectionHandler
        refresh()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createPullToRefresh()
    }
    
    func createPullToRefresh()
    {
        if #available(iOS 10.0, *)
        {
            let ptr = UIRefreshControl()
            ptr.addTarget(self, action: #selector(refresh), for: .valueChanged)
            self.tableView.refreshControl = ptr
        }
    }
    
    func refresh()
    {
        BackendAPI.typeList(category: category) { (types) in
            self.types = types
            self.tableView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return types.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        return createTypeCell(index: indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performTypeSelection(index: indexPath.row)
    }
    
    func createTypeCell(index:Int) -> UITableViewCell
    {
        let cell = UITableViewCell(style: .default, reuseIdentifier: #function)
        let type = types[index]
        
        cell.textLabel?.text = type.name
        
        return cell
    }
    
    func performTypeSelection(index:Int)
    {
        selectionHandler?(types[index])
        _ = self.navigationController?.popViewController(animated: true)
    }

}
