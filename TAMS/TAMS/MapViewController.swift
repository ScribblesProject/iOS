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
    
//    override open func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//    }
    
    //MARK: Setup
    
    open func setup(_ mode:MapViewMode, delegate del:MapViewControllerProtocol) {
        viewMode = mode
        delegate = del
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
    
    func setupForTab() {
        //Remove the "Done" button from toolbar
        if self.navigationItem.rightBarButtonItems?.count > 1 {
            self.navigationItem.rightBarButtonItems?.remove(at: 0)
        }
    }
    
    func updateForTab() {
        //Pull assets and setup pins
        reload()
    }
    
    @IBAction func resetButtonPressed(_ sender: AnyObject) {
        for (_, polyline) in self.polylines {
            self.mapView.remove(polyline)
        }
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        selectPinLocations = []
        polylines = [:]
    }
    
    func setupForSelect() {
        self.navigationItem.leftBarButtonItem = nil
        self.title = "Select Location"
        
        //Add Tap Gesture Recognizer
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleSelectPin(_:)))
        lpgr.minimumPressDuration = 0.25
        self.mapView.addGestureRecognizer(lpgr)
    }
    
    func handleSelectPin(_ recognizer:UIGestureRecognizer) {
        if recognizer.state != .began {
            return
        }
        
        let touchPoint = recognizer.location(in: self.mapView)
        let touchMapCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
        
        selectPinLocations += [touchMapCoordinate]
        
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
        point.coordinate = touchMapCoordinate
        point.title = "Dropped Pin"
        self.mapView.addAnnotation(point)
    }
    
    
    @IBAction func locateUser(_ sender: AnyObject) {
        if let loc = currentLocation {
            mapView.setCenter(loc.coordinate, animated: true)
        }
    }
    
    
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //Setup mapview for initial ping
        if currentLocation == nil {
            mapView.showsUserLocation = true
            mapView.setCenter(locations[0].coordinate, animated: true)
        }
        
        currentLocation = locations[0]
    }
    
    
    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LOCATION MANAGER ERROR: \(error)")
    }
    
    
    //Check if given list differs from global asset list
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
    
    func reload() {
        BackendAPI.list { (list) -> Void in
            
            let hasChanges = self.listDiffers(list)
            
            self.assets = list
            
            if hasChanges {
                self.layoutAssets()
            }
        }
    }
    
    func layoutAssets() {
        removePins()
        for item in assets {
            dropPins(item)
        }
    }
    
    
    func removePins() {
        for annotation in self.mapView.annotations {
            self.mapView.removeAnnotation(annotation)
        }
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
    
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineView = MKPolylineRenderer(overlay: overlay)
        lineView.strokeColor = UIColor.red
        lineView.lineWidth = 5
        return lineView
    }
    
}
