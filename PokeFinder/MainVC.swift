//
//  MainVC.swift
//  PokeFinder
//
//  Created by Nguyễn Xuân Đạt on 2/16/17.
//  Copyright © 2017 Nguyễn Xuân Đạt. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase


class MainVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var mapHasCenteredOnce = false
    var geoFire: GeoFire!
    var geoFireRef: FIRDatabaseReference!

    //
    override func viewDidLoad() {
        super.viewDidLoad()
        //
        mapView.delegate = self
        mapView.userTrackingMode = MKUserTrackingMode.follow

        // Ref to geo fire database
        geoFireRef = FIRDatabase.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)
    }

    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    func locationAuthStatus() {

        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    // CLLocationManagerDelegate
    // After user allow us to use their location
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    func centerMapOnLocation(location: CLLocation) {
        let coordinatedRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        mapView.setRegion(coordinatedRegion, animated: true)
    }
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if let loc = userLocation.location {
            // Center for the first time
            if !mapHasCenteredOnce {
                centerMapOnLocation(location: loc)
                mapHasCenteredOnce = true
            }
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // this function is called when we add new an annotatino on the map
        // addAnnotation is called
        var annotaionView: MKAnnotationView?
        let annoIdentifier = "Pokemon"


        if annotation.isKind(of: MKUserLocation.self) { // annotaion for self
            annotaionView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotaionView?.image = UIImage(named: "ash")
        } else if let deqAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annoIdentifier) { // annotaion for pokemon
            // Try to reuse annotation
            annotaionView = deqAnno
            annotaionView?.annotation = annotation
        } else { // annotation default
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoIdentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotaionView = av
        }
        // Set a button with image for current annotaion if this is a pokemon
        if let anV = annotaionView, let anno = annotation as? PokeAnnotation {
            anV.canShowCallout = true
            anV.image = UIImage(named: "\(anno.pokemonNumber)")
            let btn = UIButton()
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            btn.setImage(UIImage(named: "map"), for: .normal)
            anV.rightCalloutAccessoryView = btn
        }


        return annotaionView
    }
    // User change location by swipe change region, re generate pokemon
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showSightingsOnMap(location: loc)
    }
    // Tap the map: show the travelling distance to it
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let anno = view.annotation as? PokeAnnotation {
            var place: MKPlacemark!
            if #available(iOS 10.0, *) {
                place = MKPlacemark(coordinate: anno.coordinate)
            } else {
                // Fallback on earlier versions
                place = MKPlacemark(coordinate: anno.coordinate, addressDictionary: nil)
            }
            let destination = MKMapItem(placemark: place)
            destination.name = "Pokemon Sighting"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)

            let options = [
                MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
                MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span),
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ] as [String : Any]
            MKMapItem.openMaps(with: [destination], launchOptions: options)
        }
    }

    func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int) {
        // geo fire will go to the database to look for the key and set location of it and its data here
        geoFire.setLocation(location, forKey: "\(pokeId)")
    }

    func showSightingsOnMap(location: CLLocation) {
        // Basically if found location on map with ID we will create a add a annotation on map
        // Geo fire will go to firebase database and look all data with location and key around our current location
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        _ = circleQuery?.observe(GFEventType.keyEntered, with: { (key, location) in
            if let key = key, let location = location {
                let anno = PokeAnnotation(coordinate: location.coordinate, pokemonNumber: Int(key)!)
                self.mapView.addAnnotation(anno)

            }
        })
    }
    @IBAction func btnSpotRandomPokemon_OnPressed(_ sender: Any) {
        // Generate random pokemons
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        let rand = arc4random_uniform(151) + 1 // one of 151
        createSighting(forLocation: loc, withPokemon: Int(rand))
    }


}

