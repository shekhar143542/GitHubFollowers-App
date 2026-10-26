


import SwiftUI

struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
            } else {
                HomeView()
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            showSplash = false
        }
    }
}

#Preview {
    RootView()
}

