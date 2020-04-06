//
//  ViewController.swift
//  TravelPins
//
//  Created by Lauren Banawa on 4/5/20.
//  Copyright © 2020 Lauren Banawa. All rights reserved.
//

import UIKit
import MapKit // allows map function
import CoreLocation // enables ability to work with user location
import CoreData // allows saving to a local database

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var noteText: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager() // object used to stop and start delivery of location-related events to app
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // choose the desired level of accuracy for the location services
        locationManager.requestWhenInUseAuthorization() // request permission from the user to use location when using the app
        locationManager.startUpdatingLocation() // get the user location and give it to us
        
        // use a long press gesture to create a pin on the map
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3 // set the duration of the gesture needed in seconds
        mapView.addGestureRecognizer(gestureRecognizer)
        
    }
    
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began { // make sure that a gesture has begun before proceeding
            
            let touchedPoint = gestureRecognizer.location(in: self.mapView) // use the location from mapView to recognize the point that was touched
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView) // convert a point into coordinates
            
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            // create the location pin
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates // where to create pin
            annotation.title = nameText.text // name of the pin
            annotation.subtitle = noteText.text // small text under the name of pin
            self.mapView.addAnnotation(annotation) // add the annotation to the mapView
            
        }
        
    }
    
    
    // this is where you can get the current location information
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) // create a location with latitude and longitude
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // choose how much you want to zoom in on the map; the smaller the number, the more zoomed in
        let region = MKCoordinateRegion(center: location, span: span) // the area you'd like shown/ centered on your map
        mapView.setRegion(region, animated: true)
        
    }
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        // must use app delegate to reach and use automatically generated core data functions - use that data to save, delete and retrieve values
        let appDelegate = UIApplication.shared.delegate as! AppDelegate // must force cast this as AppDelegate to have access to AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context) // use 'context' to save and retrieve information
        
        // set values for the attributes in the Places entity
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(noteText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        // save into Core Data -- use "do, try, catch" method to avoid throwing an error
        do {
            try context.save()
            print("success")
        } catch {
            print("error")
        }
        
    }
    


}

