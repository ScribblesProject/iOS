//
//  FilterCategoryTableViewController.swift
//  TAMS
//
//  Created by Daniel Jackson on 10/1/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit

class FilterCategoryTableViewController: UITableViewController {

    typealias FilterCategorySelectionBlock = ((Category) -> Void)
    var selectionHandler:FilterCategorySelectionBlock?
    var categories:[Category] = []
    
    func prepareView(selectionHandler:@escaping FilterCategorySelectionBlock)
    {
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
        BackendAPI.categoryList { (categories) in
            self.categories = categories
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
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        return createCategoryCell(index: indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performCategorySelection(index: indexPath.row)
    }
    
    func createCategoryCell(index:Int) -> UITableViewCell
    {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: #function)
        let category = categories[index]
        
        cell.textLabel?.text = category.name
        cell.detailTextLabel?.text = category.description
        
        return cell
    }
    
    func performCategorySelection(index:Int)
    {
        selectionHandler?(categories[index])
        _ = self.navigationController?.popViewController(animated: true)
    }
}
