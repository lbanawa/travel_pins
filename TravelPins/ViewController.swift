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
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
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
        
        // retrieve saved data from Core Data if there is a title, otherwise create a new location
        if selectedTitle != "" {
            // Core Data
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubtitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        // create the annotation with the appropriate information
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        // add annotation to map
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        noteText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("error")
            }
            
            
            
        } else {
            // add new data
        }
        
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
        if selectedTitle == "" {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) // create a location with latitude and longitude
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // choose how much you want to zoom in on the map; the smaller the number, the more zoomed in
        let region = MKCoordinateRegion(center: location, span: span) // the area you'd like shown/ centered on your map
        mapView.setRegion(region, animated: true)
        } else {
            //
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        
        
        return pinView
    }
    
    // launch navigation
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                // closure
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving] // default mode of transportation is driving
                        item.openInMaps(launchOptions: launchOptions) // open the navigation -- aka Apple Maps
                        
                    }
                }
                
            }
            
        }
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
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
    


}

