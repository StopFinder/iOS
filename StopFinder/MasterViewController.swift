//
//  MasterViewController.swift
//  StopFinder
//
//  Created by mikol on 4/10/18.
//  Copyright © 2018 gc405. All rights reserved.
//

import UIKit
import Foundation
import MapKit
import CoreLocation

struct CoordinatePair : Codable {
    let lat: Double
    let lng: Double
}

struct Tip : Codable {
    let info: String
    let rating: Float
}

struct Geo : Codable {
    let location : CoordinatePair
    let viewport : VP
}

struct VP : Codable {
    let northeast : CoordinatePair
    let southwest : CoordinatePair
}

struct Stop : Codable {
    let geometry: Geo
    let icon : String
    let id : String
    let name : String
    let place_id : String
    let reference : String
    let scope : String
    let types : [String]
    let vicinity : String
//    let tips: [Tip]
}

class MasterViewController: UITableViewController {
    
    let locationManager = CLLocationManager()

    private func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) -> (lat: Double, lng: Double) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return(0, 0) }
        return (locValue.latitude, locValue.longitude)
    }
    
    
    func retrieveStops(lat: Double, lng: Double) -> ([Stop]) {
        // what do you think this function does?
        var myURLString = "https://stopfinder.gc.my/stopsnear/"
        myURLString += String(lat)
        myURLString += "/"
        myURLString += String(lng)
        myURLString += "/1600"
        guard let myURL = URL(string: myURLString) else {
            print("Error: \(myURLString) doesn't seem to be a valid URL")
            return([])
        }
        let request = URLRequest(url: NSURL(string: myURLString)! as URL)
        do {
            // Perform the request
            var response: AutoreleasingUnsafeMutablePointer<URLResponse?>? = nil
            guard let jsonData = try? NSURLConnection.sendSynchronousRequest(request, returning: response) else {
                return([])
            }
            
            let decoder = JSONDecoder()
            let stops = try? decoder.decode([Stop].self, from: jsonData)
            return(stops!)
        }
    }
    
    
    var detailViewController: DetailViewController? = nil
    var objects = ["In: College & Main", "Out: College & Main"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
        
        let stops = retrieveStops(lat: (locationManager.location?.coordinate.latitude)!, lng: (locationManager.location?.coordinate.longitude)!)
        
        for stop in stops {
            objects.append(stop.name)
        }
        
        // Do any additional setup after loading the view, typically from a nib.
        
        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc
    func insertNewObject(_ sender: Any) {
        objects.insert(String(Int(arc4random_uniform(6))), at: 0)
        // inserts new objects (me)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = String(object)
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let object = objects[indexPath.row]
        cell.textLabel!.text = String(object)
        // this line dictates what the cell text says (me)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

extension MasterViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) -> (lat: Double, long: Double) {
        if let lat = locations.last?.coordinate.latitude, let long = locations.last?.coordinate.longitude {
            return(lat, long)
        } else {
            print("No coordinates")
        }
        return(0, 0)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}


