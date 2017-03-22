//
//  BeerMeViewController.swift
//  BeerMe!
//
//  Created by Hayden Goldman on 3/21/17.
//  Copyright © 2017 Hayden Goldman. All rights reserved.
//

import UIKit
import MapKit
import RandomColorSwift

class BeerMeViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var indicatorView :UIActivityIndicatorView!
    var locationManager = CLLocationManager()
    var beerLocations = [BeerLocation]()
    var closestBeer = BeerLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        self.view.backgroundColor = randomColor(hue: .random, luminosity: .light)
        self.indicatorView.isHidden = true
        
    }
    
    private func launchTimerToLetEverythingLoad() {
        
        self.findBeers()
        sleep(2);
        self.findClosestBeer()
        
    }
    
    
    @IBAction func getBeerButtonPressed(_ sender: Any) {
        
        self.indicatorView.isHidden = false
        self.indicatorView.startAnimating()
        
        // background // lane for time consuming tasks
        DispatchQueue.global().async {
            
            self.launchTimerToLetEverythingLoad()
            
            // switch to the main thread to run UI specific tasks
            DispatchQueue.main.async {
                self.indicatorView.stopAnimating()
                self.indicatorView.isHidden = true
                
                
                guard let distance = self.closestBeer.distanceFromUser else {
                    return
                }
                
                let distanceInMiles = String(format: "%.2f", distance / 1609.34)
                
                
                // Create the alert controller
                let alertController = UIAlertController(title: "Beer Found!", message:  "\(self.closestBeer.name!): \(distanceInMiles) miles away", preferredStyle: .alert)
                
                // Create the actions
                let getBeerAction = UIAlertAction(title: "Get Directions", style: UIAlertActionStyle.default) {
                    UIAlertAction in
                    //self.performSegue(withIdentifier: "MapSegue", sender: self)
                    
                    let url  = NSURL(string: "http://maps.apple.com/?q=\(self.closestBeer.coordinate.coordinate.latitude),\(self.closestBeer.coordinate.coordinate.longitude)")
                    
                    if UIApplication.shared.canOpenURL(url! as URL) == true {
                        UIApplication.shared.open(url as! URL)
                        
                    }
                }
                let moreBeerAction = UIAlertAction(title: "More Beers", style: UIAlertActionStyle.default) {
                    UIAlertAction in
                    self.performSegue(withIdentifier: "MapSegue", sender: self)
                    
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
                    UIAlertAction in
                    
                }
                
                // Add the actions
                alertController.addAction(getBeerAction)
                alertController.addAction(moreBeerAction)
                alertController.addAction(cancelAction)
                
                // Present the controller
                self.present(alertController, animated: true, completion: nil)
                
                
            }
        }
        
        
    }
    
    func findBeers() {
        let categoryRequest = MKLocalSearchRequest()
        
        categoryRequest.naturalLanguageQuery = "bar"
        
        let region = MKCoordinateRegionMakeWithDistance((self.locationManager.location?.coordinate)!, 250, 250)
        
        categoryRequest.region = region
        
        let search = MKLocalSearch(request: categoryRequest)
        search.start { (response :MKLocalSearchResponse?, error: Error?) in
            
            for requestItem in (response?.mapItems)! {
                
                let beerLocation = BeerLocation()
                beerLocation.name = requestItem.name
                beerLocation.coordinate = requestItem.placemark.location
                beerLocation.address = requestItem.placemark.addressDictionary?["FormattedAddressLines"] as! [String]
                beerLocation.street = requestItem.placemark.addressDictionary?["Street"] as! String!
                beerLocation.city = requestItem.placemark.addressDictionary?["City"] as! String
                beerLocation.state = requestItem.placemark.addressDictionary?["State"] as! String
                beerLocation.zip = requestItem.placemark.addressDictionary?["ZIP"] as! String
                
                self.beerLocations.append(beerLocation)
            }
        }
        
    }
    
    //Finding the location that is closest to the user
    func findClosestBeer() {
        
        var distances = [Double]()
        
        //looping to get all the location distance from user
        for locationDistance in self.beerLocations {
            
            let distance = self.locationManager.location?.distance(from: locationDistance.coordinate)
            locationDistance.distanceFromUser = distance as Double!
            distances.append(distance!)
            
        }
        
        let minDistance = distances.min()
        
        //setting the closest location object to the location with the closest distance
        for location in self.beerLocations {
            
            if self.locationManager.location?.distance(from: location.coordinate) == minDistance {
                self.closestBeer = location
            }
        }
    }
    
    
    
    
    
}
