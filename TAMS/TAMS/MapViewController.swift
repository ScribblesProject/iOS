//
//  MapViewController.swift
//  TAMS
//
//  Created by Daniel Jackson on 3/17/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


public protocol MapViewControllerProtocol {
    func didSelectLocations(_ locations:[CLLocationCoordinate2D])
}

public enum MapViewMode {
    case tab //Default
    case select
}

open class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var currentLocation:CLLocation?;
    var viewMode:MapViewMode = .tab
    
    var assets = [Asset]()
    var filterNoticeView:UIView?
    var filterCategory:Category?
    var filterType:Type?
    var filteredAssets:[Asset]?
    
    //For Creating Locations
    var selectPinLocations:[CLLocationCoordinate2D] = []
    var delegate:MapViewControllerProtocol?
    var polylines:[NSNumber:MKPolyline] = [:] // [ Asset.id : MKPolygon ]
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        startUpdatingLocation()
        setupInitialMapPosition()
        
        switch viewMode {
        case .tab:
            setupForTab()
        case .select:
            setupForSelect()
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        switch viewMode {
        case .tab:
            updateForTab()
        case .select:
            break
//            setupForSelect()
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        delegate?.didSelectLocations(selectPinLocations)
    }
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "presentFilter"
        {
            let destination = segue.destination as! FilterTableViewController
            
            destination.prepareView(category: filterCategory, type: filterType, applyHandler: { (category, type) in
                
                self.filterCategory = category
                self.filterType = type
                self.filterResults(category, type)
            })
        }
    }
    
    //MARK: - 
    //MARK: Filter
    
    func filterResults(_ category:Category?, _ type:Type?)
    {
        if category == nil && type == nil
        {
            filteredAssets = nil
            self.layoutAssets()
            return
        }
        
        filteredAssets = assets.filter({ (asset) -> Bool in
            if category != nil
            {
                if asset.category.name != category!.name {
                    return false
                }
            }
            
            if type != nil
            {
                if asset.type != type!.name {
                    return false
                }
            }
            
            return true
        })
        
        self.layoutAssets()
    }
    
    //MARK: -
    //MARK: Pin Setup
    
    func reload() {
        BackendAPI.list { (list) -> Void in
            if self.listDiffers(list) {
                self.assets = list
                self.layoutAssets()
            }
        }
    }
    
    func layoutAssets() {
        resetButtonPressed(nil)
        
        var useAssets = assets
        if filteredAssets != nil {
            useAssets = filteredAssets!
            displayFilterNotice()
        }
        else
        {
            hideFilterNotice()
        }
        
        for item in useAssets {
            dropPins(item)
        }
    }
    
    func displayFilterNotice()
    {
        hideFilterNotice()
        
        filterNoticeView = UIView()
        filterNoticeView?.layer.cornerRadius = 22.0
        filterNoticeView?.layer.borderColor = UIColor.gray.cgColor
        filterNoticeView?.layer.borderWidth = 1.0
        filterNoticeView?.backgroundColor = UIColor(white: 1.0, alpha: 0.75)
        
        let filterNoticeLabel = UILabel()
        filterNoticeLabel.text = "Filter Applied"
        filterNoticeLabel.textAlignment = .center
        filterNoticeLabel.textColor = UIColor.gray
        filterNoticeView?.addSubview(filterNoticeLabel)
        
        filterNoticeLabel.translatesAutoresizingMaskIntoConstraints = false
        var views:[String:Any] = ["label":filterNoticeLabel]
        var vert = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[label]-0-|", options: .init(rawValue: 0), metrics: nil, views: views)
        var horiz = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[label]-0-|", options: .init(rawValue: 0), metrics: nil, views: views)
        filterNoticeView?.addConstraints(vert + horiz)
        
        self.view.addSubview(filterNoticeView!)
        
        filterNoticeView?.translatesAutoresizingMaskIntoConstraints = false
        views = ["view":filterNoticeView!, "guide":self.bottomLayoutGuide]
        vert = NSLayoutConstraint.constraints(withVisualFormat: "V:[view(44)]-20-[guide]", options: .init(rawValue: 0), metrics: nil, views: views)
        horiz = NSLayoutConstraint.constraints(withVisualFormat: "H:[view(200)]", options: .init(rawValue: 0), metrics: nil, views: views)
        let centered = NSLayoutConstraint(item: filterNoticeView!, attribute: .centerX, relatedBy: .equal, toItem: filterNoticeView!.superview!, attribute: .centerX, multiplier: 1.0, constant: 0)
        self.view.addConstraints(vert + horiz + [centered])
    }
    
    func hideFilterNotice()
    {
        filterNoticeView?.removeFromSuperview()
        filterNoticeView = nil
    }
    
    /// Check if given list differs from global asset list .. for updating
    func listDiffers(_ list:[Asset])->Bool {
        
        //Array of Asset.LocationType
        var currentAssetLocs = [String : Any]()
        
        var hasChanges = false
        if list.count != self.assets.count {
            //Are counts different?
            hasChanges = true
        }
        else {
            //Store location dict for easy lookup
            for item in self.assets {
                currentAssetLocs[item.name] = item.locations
            }
            //For each list item, lookup currentAssetLoc
            for item in list {
                if let match = currentAssetLocs[item.name] as? [Int:Asset.LocationType] {
                    if item.locations.count != match.count {
                        hasChanges = true
                        break
                    }
                    
                    for (order, currentLoc) in match
                    {
                        if let itemLoc = item.locations[order] {
                            if currentLoc != itemLoc {
                                hasChanges = true
                                break
                            }
                        }
                        else {
                            hasChanges = true
                            break
                        }
                    }
                }
                else {
                    hasChanges = true
                }
            }
        }
        return hasChanges
    }
    
    func dropPins(_ ast:Asset)
    {
        setupPolygon(ast)
        
        for (_, loc) in ast.locations {
            let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
            let point = MKPointAnnotation()
            point.coordinate = coord
            point.title = ast.name
            point.subtitle = ast.description
            self.mapView.addAnnotation(point)
        }
    }
    
    
    func setupPolygon(_ ast:Asset)
    {
        if ast.locations.count > 1 {
            
            //Remove current polygon
            if let currentPolygon = polylines[ast.id] {
                self.mapView.remove(currentPolygon)
            }
            
            //Sort locations by order key
            let locDictionaries = ast.locations.sorted(by: { (first, second) -> Bool in
                return Int(first.key) < Int(second.key)
            })
            
            //Add locations to array
            let locs:[CLLocationCoordinate2D] = locDictionaries.map({ (item) -> CLLocationCoordinate2D in
                return CLLocationCoordinate2D(latitude:item.value.latitude, longitude: item.value.longitude)
            })
            
            //Save the polygon
            polylines[ast.id] = MKPolyline(coordinates: locs + [locs[0]], count: locs.count+1)
            self.mapView.add(polylines[ast.id]!)
        }
    }
    
    //MARK: -
    //MARK: Setup
    
    func setupTab(delegate:MapViewControllerProtocol) {
        self.viewMode = .tab
        self.delegate = delegate
    }
    
    func setupAssetSelect(locations:[Int:Asset.LocationType]? = nil, delegate:MapViewControllerProtocol) {
        self.viewMode = .select
        self.delegate = delegate
        
        if locations != nil {
            let locArray = locations!.sorted { (itemA, itemB) -> Bool in
                return itemA.key < itemB.key
            }
            
            self.selectPinLocations = locArray.map({ (item) -> CLLocationCoordinate2D in
                return CLLocationCoordinate2D(latitude: item.value.latitude, longitude: item.value.longitude)
            })
        }
    }
    
    func startUpdatingLocation() {
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    func setupInitialMapPosition() {
        let location = CLLocationCoordinate2D(latitude: 38.5815719, longitude: -121.49439960000001)
        let region = MKCoordinateRegionMakeWithDistance(location, 20000, 20000)
        self.mapView.setRegion(region, animated: false)
    }
    
    private func setupForTab() {
        //Remove the "Done" button from toolbar
        if self.navigationItem.rightBarButtonItems?.count > 1 {
            self.navigationItem.rightBarButtonItems?.remove(at: 0)
        }
    }
    
    private func setupForSelect() {
        self.navigationItem.leftBarButtonItem = nil
        self.title = "Select Location"
        
        //Add Tap Gesture Recognizer
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleSelectPin(_:)))
        lpgr.minimumPressDuration = 0.25
        self.mapView.addGestureRecognizer(lpgr)
        
        
        for (_, polyline) in self.polylines {
            self.mapView.remove(polyline)
        }
        self.mapView.removeAnnotations(self.mapView.annotations)
        for loc in self.selectPinLocations {
            addDroppedCoordinate(coord: loc)
        }
        
        if self.selectPinLocations.count > 0 {
            self.mapView.setCenter(self.selectPinLocations[0], animated: true)
        }
    }
    
    func updateForTab() {
        //Pull assets and setup pins
        reload()
    }
    
    //MARK: -
    //MARK: Action Handlers
    
    @IBAction func resetButtonPressed(_ sender: AnyObject?) {
        for (_, polyline) in self.polylines {
            self.mapView.remove(polyline)
        }
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        selectPinLocations = []
        polylines = [:]
    }
    
    @IBAction func locateUser(_ sender: AnyObject) {
        if let loc = currentLocation {
            mapView.setCenter(loc.coordinate, animated: true)
        }
    }
    
    func handleSelectPin(_ recognizer:UIGestureRecognizer) {
        if recognizer.state != .began {
            return
        }
        
        let touchPoint = recognizer.location(in: self.mapView)
        let touchMapCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)

        selectPinLocations += [touchMapCoordinate]
        
        addDroppedCoordinate(coord: touchMapCoordinate)
    }
    
    func addDroppedCoordinate(coord:CLLocationCoordinate2D)
    {
        //A
        if selectPinLocations.count > 1 {
            let saveKey = NSNumber(value: 0)
            
            //Remove current
            if let currentPolygon = polylines[saveKey] {
                self.mapView.remove(currentPolygon)
            }
            
            //Save the polygon
            polylines[saveKey] = MKPolyline(coordinates: selectPinLocations + [selectPinLocations[0]], count: selectPinLocations.count+1)
            self.mapView.add(polylines[saveKey]!)
        }
        
        let point = MKPointAnnotation()
        point.coordinate = coord
        point.title = "Dropped Pin"
        self.mapView.addAnnotation(point)
    }
    
    //MARK: -
    //MARK: Location Protocol
    
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //Setup mapview for initial ping
        if currentLocation == nil {
            if selectPinLocations.count == 0 && assets.count == 0 {
                mapView.showsUserLocation = true
                mapView.setCenter(locations[0].coordinate, animated: true)
            }
        }
        
        currentLocation = locations[0]
    }
    
    
    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LOCATION MANAGER ERROR: \(error)")
    }
    
    open func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for annView in views
        {
            let endFrame = annView.frame;
            annView.frame = endFrame.offsetBy(dx: 0, dy: -500);
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                annView.frame = endFrame
            })
        }
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineView = MKPolylineRenderer(overlay: overlay)
        lineView.strokeColor = UIColor.red
        lineView.lineWidth = 5
        return lineView
    }
    
}
