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

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var mapView: MKMapView!
    var assets = [Asset]()
    let locationManager = CLLocationManager()
    var currentLocation:CLLocation?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ask for Authorisation from the User.
//        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    
        let location = CLLocationCoordinate2D(latitude: 38.5815719, longitude: -121.49439960000001)
        let region = MKCoordinateRegionMakeWithDistance(location, 20000, 20000)
        self.mapView.setRegion(region, animated: false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        reload()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func locateUser(sender: AnyObject) {
        if let loc = currentLocation {
            mapView.setCenterCoordinate(loc.coordinate, animated: true)
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations[0]
//        print("Latitude: \(location.coordinate.latitude). Longitude: \(location.coordinate.longitude).")
        mapView.showsUserLocation = true
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("LOCATION MANAGER ERROR: \(error)")
    }
    
    func listDiffers(list:[Asset])->Bool {
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
    
    func dropPin(ast:Asset)
    {
        let coord = CLLocationCoordinate2D(latitude: ast.latitude, longitude: ast.longitude)
        let point = MKPointAnnotation()
        point.coordinate = coord
        point.title = ast.name
        point.subtitle = ast.description
        self.mapView.addAnnotation(point)
    }
    
}
