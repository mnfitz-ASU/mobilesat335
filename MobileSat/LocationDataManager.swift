import CoreLocation

class LocationDataManager : NSObject, ObservableObject, CLLocationManagerDelegate
{
    var locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus?

    override init()
    {
      super.init()
      locationManager.delegate = self
    }

    func requestLocation()
    {
        if (locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways)
        {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        location = locations.first?.coordinate
    }
    
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager)
    {
        switch manager.authorizationStatus
        {
        case .authorizedWhenInUse:  // Location services are available.
            // Insert code here of what should happen when Location services are authorized
            authorizationStatus = .authorizedWhenInUse
            locationManager.requestLocation()
            break
            
        case .restricted:  // Location services currently unavailable.
            // Insert code here of what should happen when Location services are NOT authorized
            authorizationStatus = .restricted
            break
            
        case .denied:  // Location services currently unavailable.
            // Insert code here of what should happen when Location services are NOT authorized
            authorizationStatus = .denied
            break
            
        case .notDetermined:        // Authorization not determined yet.
            authorizationStatus = .notDetermined
            manager.requestWhenInUseAuthorization()
            break
            
        default:
            break
        }
    }
        
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("error: \(error.localizedDescription)")
    }
}

/*
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate
{
    let manager = CLLocationManager()

    @Published var location: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
    }
}*/
