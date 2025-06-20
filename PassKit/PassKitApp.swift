import SwiftUI

@main
struct PassKitApp: App {
    @StateObject private var model = PassKitAppModel()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                FrostBackground()
                if model.showWelcome {
                    WelcomeScreen {
                        withAnimation { model.showWelcome = false }
                    }
                } else {
                    AppContentView()
                        .environmentObject(model)
                }
            }
            .frame(minWidth: 880, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }
}

