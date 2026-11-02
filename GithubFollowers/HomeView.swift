
import SwiftUI
import UIKit

struct HomeView: View {
    var body: some View {
        MainTabBarControllerRepresentable().ignoresSafeArea()
    }
}

struct MainTabBarControllerRepresentable: UIViewControllerRepresentable {

    func makeUIViewController(
        context: Context
    ) -> MainTabBarController {

        return MainTabBarController()
    }

    func updateUIViewController(
        _ uiViewController: MainTabBarController,
        context: Context
    ) {
    }
}

#Preview {
    HomeView()
}
