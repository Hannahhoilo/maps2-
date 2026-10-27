import SwiftUI

@main struct MyApp: App {
    
    @State private var placesRepository: PlacesRepositoryProtocol
    
    init(){
        self.placesRepository = PlacesRepository()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.placesRepository, placesRepository)
        }
    }
}

extension EnvironmentValues{
    @Entry var placesRepository: any PlacesRepositoryProtocol = PlacesRepository()
}
