import SwiftUI
import SwiftData

@main
struct RoamlyApp: App {
    @State private var appState = AppState.shared
    private let container: ModelContainer
    
    init() {
        self.container = DataContainer.create()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .modelContainer(container)
                .preferredColorScheme(appState.settings.appearance.colorScheme)
        }
    }
}
