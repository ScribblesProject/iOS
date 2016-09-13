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
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
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
    
    @IBAction func doneButtonPressed(_ sender: AnyObject) {
        delegate?.didSelectLocations(selectPinLocations)
        self.navigationController?.popViewController(animated: true)
    }
    
    func setupForSelect() {
        self.navigationItem.leftBarButtonItem = nil
        self.title = "Select Location"
        
        //Add Tap Gesture Recognizer
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleSelectPin(_:)))
        lpgr.minimumPressDuration = 1.0
        self.mapView.addGestureRecognizer(lpgr)
    }
    
    func handleSelectPin(_ recognizer:UIGestureRecognizer) {
        if recognizer.state != .began {
            return
        }
        
        print("Dropping Pin")
        
        //Remove all pins
        selectPinLocations = []
        for pin in self.mapView.annotations {
            self.mapView.removeAnnotation(pin)
        }
        
        let touchPoint = recognizer.location(in: self.mapView)
        let touchMapCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
        
        selectPinLocations += [touchMapCoordinate]
        
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
        }
        
        currentLocation = locations[0]
    }
  open   
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LOCATION MANAGER ERROR: \(error)")
    }
    
    func listDiffers(_ list:[Asset])->Bool {
        var currentAssetNames = [String:(lat:Double, long:Double)]()
        var hasChanges = false
        if list.count != self.assets.count {
            //Are counts different?
            hasChanges = true
        }
        else {
            //Or, check for differences in name/lat/long
            for item in self.assets {
                currentAssetNames[item.name] = (lat:item.latitude, long:item.longitude)
            }
            for item in list {
                if let match = currentAssetNames[item.name] {
                    if match.lat != item.latitude || match.long != item.longitude {
                        hasChanges = true
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
//            [UIView animateWithDuration:0.5
//                animations:^{ annView.frame = endFrame; }];
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
            dropPin(item)
        }
    }
    
    func removePins() {
        for annotation in self.mapView.annotations {
            self.mapView.removeAnnotation(annotation)
        }
    }
    
    func dropPin(_ ast:Asset)
    {
        let coord = CLLocationCoordinate2D(latitude: ast.latitude, longitude: ast.longitude)
        let point = MKPointAnnotation()
        point.coordinate = coord
        point.title = ast.name
        point.subtitle = ast.description
        self.mapView.addAnnotation(point)
    }
    
}
