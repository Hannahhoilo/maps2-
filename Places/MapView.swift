import SwiftUI

import MapKit

enum AnnotationDetailLevel {
    case dot, full
    
    init(distance: Double) {
        if distance < 2000 {
            self = .full
        } else {
            self = .dot
        }
    }
}

struct MapView: View {
    
    /// The detail level at which our custom annotations shlould be rendered
    @State private var detailLevel: AnnotationDetailLevel = .full
    
    /// Get our repository which is an instance of `PlacesRepositoryProtocol`
    @Environment(\.placesRepository) private var placesRepository
    
    /// Position of where to place the camera
    private static let centerPosition: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522)
    private static let distanceMeters: Double = 5000
    @State private var camera: MapCameraPosition = .camera(MapCamera(centerCoordinate: centerPosition, distance: distanceMeters))
    
    /// What heights the sheet can exist in
    private let possibleSheetDetents: Set<PresentationDetent> = [.height(150), .medium, .large]
    
    /// Current height of the sheet
    @State private var sheetDetent: PresentationDetent = .height(150)
    
    /// Styling of the map
    private static let pointsOfInterestTypes: PointOfInterestCategories = .including([.cafe, .museum, .university, .park])
    private let mapStyle: MapStyle = .standard(emphasis: .muted, pointsOfInterest: pointsOfInterestTypes)
    
    /// When you tap an Apple-made POI, you are returned a `MapFeature`
    /// This `MapFeature` can be transformed into a `MapItem` using
    /// Apple's private API's
    /// Its optional, because whenever you click something random, it will be unselected
    /// And you wont actually have a feature
    @State private var selectedMapFeature: MapFeature?
    
    /// The item which is derived from our `MapFeature`
    @State private var mapItem: MKMapItem? {
        /// kjører hver gang den er satt
        didSet{
            
            if mapItem == nil {
                sheetDetent = .height(150)
            } else {
                sheetDetent = .medium
            }
        }
    }
    
    private var mapItemViewStyle: (categoryName: String, categorySymbol: String, categoryColor: Color){
        
        guard let category = mapItem?.pointOfInterestCategory else {
            return("Unknown Category", "mappin",.red)
        }
        
        switch category {
        case.cafe:
            return ("Cafe", "cup.and.saucerr.fill", .brown)
        case.museum:
            return ("Museum", "building.columns.fill", .pink)
        case.park:
            return ("Park", "tree.fill", .green)
        default:
            return ("Place", "mappin", .red)
        }
    }
    
    var body: some View {
        makeMapView()
    }
    
    // MARK: - View Functions
    
    private func makeMapView() -> some View {
        Map(position: $camera, selection: $selectedMapFeature){
            makeCustomAnnotationViews()
        }
            .mapStyle(mapStyle)
            .onMapCameraChange(frequency: .continuous) { cameraUpdateContext in
                didChangeCameraZoom(cameraUpdateContext.camera.distance)
                didSwipeMap()
            }
            .onChange(of: selectedMapFeature) { oldMapFeature, newMapFeature in
                print("SELECTED: Map feature selected")
                didChangeMapFeature(oldMapFeature: oldMapFeature, newMapFeature: newMapFeature)
            }
            .sheet(isPresented: .constant(true)) {
                makeSheetView()
                    .presentationDetents(possibleSheetDetents, selection: $sheetDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .interactiveDismissDisabled()
            }
    }
    
    private func makeCustomAnnotationViews() -> some MapContent{
        ForEach(placesRepository.places) { place in
            Annotation(place.title, coordinate: place.coordinate){
                
            }
        }
    }
    
    private func makeAnnotationContentView() -> some View {
        let isFull: Bool
        if detailLevel == .full {
            isFull = true
        } else {
            isFull = false
        }
        return Circle()
            .fill(.orange)
            .frame(width: isFull ? 36 : 12, height: isFull ? 36 : 12 )
            .overlay {
                Image(systemName: "star.fill")
                    .foregroundStyle(.white)
                    .scaleEffect(isFull ? 1 : 0.3)
                    .opacity(isFull ? 1 : 0)
            }
            .frame(width: 36, height: 36)
            .animation(.easeInOut(duration: 0.2), value: isFull)
    }
    
    @ViewBuilder
    private func makeSheetView() -> some View {
        if let unwrappedMapItem = mapItem {
            NavigationStack {
                makeMapItemView(mapItem: unwrappedMapItem)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction){
                            Button {
                                selectedMapFeature = nil
                                mapItem = nil
                            } label: {
                                Label("Close", systemImage: "xmark")
                            }
                        }
                    }
            }
        } else {
            Text("Hello World")
        }
    }
    
    private func makeMapItemView(mapItem: MKMapItem) -> some View {
        List {
            makeHeaderView(mapItem: mapItem)
        }
    }
    
    private func makeHeaderView(mapItem: MKMapItem) -> some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: mapItemViewStyle.categorySymbol)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(mapItemViewStyle.categoryColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mapItem.name ?? "Unknown Place")
                        .font(.title2.bold())
                    Text(mapItemViewStyle.categoryName)
                        .foregroundStyle(.secondary)
                }
            }
            
            makeActionButtonsView()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    private func makeActionButtonsView() -> some View {
        HStack {
            Button {
                mapItem?.openInMaps()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.title3)
                    Text("Directions")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }

            // lots of optional unwraps to make a link
            if let unwrappedPhoneNumber = mapItem?.phoneNumber{
                
                let filteredPhoneNumber = unwrappedPhoneNumber.filter{ character in
                    return character.isNumber || character == "+"
                }
                
                if let phoneURL = URL(string: "tel:\(filteredPhoneNumber)"){
                    Link(destination:phoneURL){
                        VStack(spacing:4){
                            Image(systemName: "phone.fill")
                                .font(.title3)
                            Text("Call")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                }
            }
            
            if let unwrappedURL = mapItem?.url {
                Link(destination: unwrappedURL) {
                    VStack(spacing: 4) {
                        Image(systemName: "safari.fill")
                            .font(.title3)
                        Text("Website")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
            }
        }
        .buttonStyle(.bordered)
    }
    
    // MARK: - Methods
    
    private func didChangeCameraZoom(_ zoomDistance: Double) {
        let newDetailLevel: AnnotationDetailLevel = AnnotationDetailLevel(distance: zoomDistance)
        /// if the new detaillevel is the same as the old one
        /// we dont update our state variav´ble
        /// our views will not be drawn
        guard newDetailLevel != detailLevel else {
            return
        }
        
        /// if it is different, then we update out state variable
        /// and this will cause views that read it to be redrawn
        detailLevel = newDetailLevel
    }
    
    private func didSwipeMap() {
        guard camera.positionedByUser else {
            return
        }
        
        updateSheetDetentsIfNeeded()
    }
    
    private func updateSheetDetentsIfNeeded() {
        guard sheetDetent != .height(150) else {
            return
        }
        
        sheetDetent = .height(150)
    }
    
    private func didChangeMapFeature(oldMapFeature: MapFeature?, newMapFeature: MapFeature?) {
        /// Has the user selected a new POI?
        guard let newMapFeature else {
            mapItem = nil
            return
        }
        
        let requestToGetMapItem: MKMapItemRequest = MKMapItemRequest(feature: newMapFeature)
        
        Task {
            guard let newMapItem = try? await requestToGetMapItem.mapItem else {
                return
            }
            mapItem = newMapItem
            
            
            
            let latitude = newMapItem.location.coordinate.latitude - 0.005 //plassering
            let longitude = newMapItem.location.coordinate.longitude
            let centerCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let newCamera: MapCamera = MapCamera(centerCoordinate: centerCoordinate, distance: 5000)
            
            withAnimation{
                camera = .camera(newCamera)
            }
        }
    }
}

#Preview {
    MapView()
}
