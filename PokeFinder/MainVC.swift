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
        var annotaionView: MKAnnotationView?
        if annotation.isKind(of: MKUserLocation.self) {
            annotaionView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotaionView?.image = UIImage(named: "ash")
        }
        return annotaionView
    }

    func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int) {
        // geo fire will go to the database to look for the key and set location of it and its data here
        geoFire.setLocation(location, forKey: "\(pokeId)")
    }


    @IBAction func btnSpotRandomPokemon_OnPressed(_ sender: Any) {
    }


}

