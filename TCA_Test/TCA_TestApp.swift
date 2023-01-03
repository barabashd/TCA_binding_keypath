import SwiftUI

@main
struct TCA_TestApp: App {
    var body: some Scene {
        WindowGroup {
            MainView(
                store: .init(
                    initialState: .init(),
                    reducer: MainView.reducer,
                    environment: MainView.Environment.init()
                )
            )
        }
    }
}
