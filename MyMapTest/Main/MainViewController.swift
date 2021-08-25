//
//  ViewController.swift
//  MyMapTest
//
//  Created by D02020015 on 2021/5/19.
//

import UIKit
import GoogleMaps
import GooglePlaces

class MainViewController: UIViewController {
    
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placeClient: GMSPlacesClient!
    var preciseLocationZoomLevel: Float = 15.0
    var approximateLocationZoomLevelt: Float = 10.0
    
    var searchBar: UISearchBar!
    private var tableView: UITableView!
    private var tableDataSource: GMSAutocompleteTableDataSource!
    
    private var lat: Double = 25.033671
    private var lng: Double = 121.564427
    
    @IBAction func openMap(_ sender: UIBarButtonItem) {
        
        let url = URL(string: "comgooglemaps://?saddr=&daddr=\(lat),\(lng)&directionsmode=driving")
                
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        } else {
            // 若手機沒安裝 Google Map App 則導到 App Store(id443904275 為 Google Map App 的 ID)
            let appStoreGoogleMapURL = URL(string: "itms-apps://itunes.apple.com/app/id585027354")!
            UIApplication.shared.open(appStoreGoogleMapURL, options: [:], completionHandler: nil)
        }
    }
    
    //var resultsViewController: GMSAutocompleteResultsViewController?
    //var searchController: UISearchController?
    //var resultView: UITextView?
    
    var zoomLevel: Float {
        return locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevelt
    }
    
    // An array to hold the list of likely places.
    //var likelyPlaces: [GMSPlace] = []
    // The currently selected place.
    //var selectedPlace: GMSPlace?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a map to display
        /*let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
        self.view.addSubview(mapView)
        // Creates a marker in the center of the map.
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.20)
        marker.title = "Sydney"
        marker.snippet = "Australia"
        marker.map = mapView*/

        //initMapSearchController()
        initLocationManager()
        initStackView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setMapPlace()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func initStackView() {
        let stackView = UIStackView()
        
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0
        
        initMapSearchBar()
        initMapView()
        
        stackView.addArrangedSubview(searchBar)
        stackView.addArrangedSubview(tableView)
        stackView.addArrangedSubview(mapView)
        
        self.view.addSubview(stackView)
        
        let safe = view.safeAreaLayoutGuide
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: safe.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: safe.bottomAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: safe.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: safe.trailingAnchor).isActive = true
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.heightAnchor.constraint(equalToConstant: 200).isActive = true
    }
    
    func initMapSearchBar() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        
        tableDataSource = GMSAutocompleteTableDataSource()
        tableDataSource.delegate = self
        
        tableView = UITableView()
        tableView.delegate = tableDataSource
        tableView.dataSource = tableDataSource
        //view.addSubview(tableView)
    }
    
    /*func initMapSearchController() {
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        // Put the search bar in the navigation bar.
        //searchController?.searchBar.sizeToFit()
        //navigationItem.titleView = searchController?.searchBar
        
        // Add the search bar to the right of the nav bar,
        // use a popover to display the results.
        // Set an explicit size as we don't want to use the entire nav bar.
        searchController?.searchBar.frame = (CGRect(x: 0, y: 0, width: 250.0, height: 44.0))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: (searchController?.searchBar)!)
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        definesPresentationContext = true
        // Prevent the navigation bar from being hidden when searching.
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.modalPresentationStyle = .popover
    }*/

    func initMapView() {
        let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude, longitude: defaultLocation.coordinate.longitude, zoom: zoomLevel)
        
        mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        
        //view.addSubview(mapView)
        mapView.isHidden = true
    }
    
    func initLocationManager() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 50
        locationManager.delegate = self
        //locationManager.startUpdatingLocation()
        
        placeClient = GMSPlacesClient.shared()
    }
    
    func listLikelyPlaces() {
        MapData.likelyPlaces.removeAll()
        
        let placeFields: GMSPlaceField = [.name, .coordinate, .placeID]
        
        placeClient.findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: placeFields) { (placeLikelihoods, error) in
            guard error == nil else {
                print("Current Place error: \(error!.localizedDescription)")
                return
            }
            
            guard let placeLikelihoods = placeLikelihoods else {
                print("No places found.")
                return
            }
            
            for likelihood in placeLikelihoods {
                print("likelidhood \(likelihood)")
                MapData.likelyPlaces.append(likelihood.place)
            }
        }
    }
    
    func setMapPlace() {
        print("set map place \(MapData.selectedPlace)")
        guard let place = MapData.selectedPlace else {
            return
        }
        mapView.clear()

        // Add a marker to the map.
        let marker = GMSMarker(position: place.coordinate)
        marker.title = place.name
        marker.snippet = place.formattedAddress
        marker.map = mapView
       
        let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: zoomLevel)
        mapView.animate(to: camera)
        //listLikelyPlaces()
    }
    
    //經緯度轉地址
    func getGeocodeLocationFromAddressString(latitude: Double, longitude: Double, Completion: @escaping((GMSAddress?, Error?) -> ())) {
        let reverseGeoCoder = GMSGeocoder()
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        reverseGeoCoder.reverseGeocodeCoordinate(coordinate) {(placemark, error) -> Void in
            guard let placemarkObj = placemark?.firstResult(), error == nil else {
                Completion(nil, error)
                return
            }
            
            print("placemark \(placemarkObj.lines?.first)")
            Completion(placemarkObj, error)
            
        }
    }
}

extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: zoomLevel)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        }
        else {
            mapView.animate(to: camera)
        }
        getGeocodeLocationFromAddressString(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) { (placemark, error) in
            
        }
        listLikelyPlaces()
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    // Check accuracy authorization
        let accuracy = manager.accuracyAuthorization
        switch accuracy {
        case .fullAccuracy:
            print("Location accuracy is precise.")
        case .reducedAccuracy:
            print("Location accuracy is not precise.")
        @unknown default:
            fatalError()
        }
        // Handle authorization status
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways:
            print("Location status is Always.")
            locationManager.requestLocation()
        case .authorizedWhenInUse:
            print("Location status is OK.")
            locationManager.requestLocation()
        @unknown default:
            fatalError()
        }
    }
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

extension MainViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Update the GMSAutocompleteTableDataSource with the search text.
        print("search Bar text \(searchText)")
        self.view.endEditing(true)
        placeClient.findAutocompletePredictions(fromQuery: searchText, filter: nil, sessionToken: nil){ prediction, error in
            print("prediction: \(prediction?.first), placeid: \(prediction?.first?.placeID)error: \(error)")
            if let placeID = prediction?.first?.placeID {
                let placeFields: GMSPlaceField = [.name, .coordinate, .formattedAddress, .placeID]
                self.placeClient.fetchPlace(fromPlaceID: placeID, placeFields: placeFields, sessionToken: nil) { placemark, error in
                    print("search placemark: \(placemark), error: \(error) \(placemark?.coordinate)")
                    if let placemark = placemark {
                        self.lat = placemark.coordinate.latitude
                        self.lng = placemark.coordinate.longitude
                    }
                }
//                self.placeClient.lookUpPlaceID(placeID) { placemark, error in
//                    print("search placemark: \(placemark), error: \(error)")
//                }
            }
        }
        
        tableDataSource.sourceTextHasChanged(searchText)
    }
}

extension MainViewController: GMSAutocompleteTableDataSourceDelegate {
    func didUpdateAutocompletePredictions(for tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator off.
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        //print("Update Predictions \(tableDataSource)")
        // Reload table data.
        tableView.reloadData()
    }
    
    func didRequestAutocompletePredictions(for tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator on.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        //print("Request Predictions \(tableDataSource)")
        // Reload table data.
        tableView.reloadData()
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didAutocompleteWith place: GMSPlace) {
        // Do something with the selected place.
//        print("Place name: \(String(describing: place.name))")
//        print("Place address: \(String(describing: place.formattedAddress))")
//        print("Place placeID: \(String(describing: place.placeID))")
//        print("Place coordinate: \(place.coordinate)")
        MapData.selectedPlace = place
        setMapPlace()
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didFailAutocompleteWithError error: Error) {
        // Handle the error.
        print("Error: \(error.localizedDescription)")
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didSelect prediction: GMSAutocompletePrediction) -> Bool {
        return true
    }
}

/*extension MainViewController: GMSAutocompleteResultsViewControllerDelegate {
  func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didAutocompleteWith place: GMSPlace) {
    searchController?.isActive = false
    // Do something with the selected place.
    print("Place name: \(place.name)")
    print("Place address: \(place.formattedAddress)")
    print("Place attributions: \(place.attributions)")
  }

  func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didFailAutocompleteWithError error: Error){
    // TODO: handle the error.
    print("Error: ", error.localizedDescription)
  }

  // Turn the network activity indicator on and off again.
  func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
  }

  func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
  }
}*/
