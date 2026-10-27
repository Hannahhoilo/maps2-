import Observation
import MapKit

protocol PlacesRepositoryProtocol {
    var places: [Place] {get}
}

struct Place: Identifiable {
    let id: UUID = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
    let tip: String
    let bestTime: String
}

@Observable
final class PlacesRepository: PlacesRepositoryProtocol {
    private(set) var places: [Place] = []
    
    init() {
        self.places = places
    }
    
    func fillInPlacesArray() -> [Place] {
        return [
            Place(title: "Secret Sunset Bench", coordinate: CLLocationCoordinate2D(latitude: 59.9068, longitude: 10.7632), tip: "Bring a blanket, the wind picks up after 8", bestTime: "One hour before sunset"),
            Place(title: "Best Street Art Alley", coordinate: CLLocationCoordinate2D(latitude: 59.9226, longitude: 10.7580), tip: "New pieces appear every few weeks", bestTime: "Weekday mornings"),
            Place(title: "Cinnamon Bun Hall of Fame", coordinate: CLLocationCoordinate2D(latitude: 59.9186, longitude: 10.7100), tip: "Ask for the one still warm", bestTime: "Before 10:00"),
            Place(title: "Cold Dip Spot", coordinate: CLLocationCoordinate2D(latitude: 59.9040, longitude: 10.7570), tip: "Shoes on, the rocks are sharp", bestTime: "Early morning, any season"),
            Place(title: "Hammock Hill", coordinate: CLLocationCoordinate2D(latitude: 59.9255, longitude: 10.7415), tip: "Two trees about 3 m apart", bestTime: "Summer afternoons")
        ]
    }
}
