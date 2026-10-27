
import SwiftUI
import UIKit

struct HomeView: View {
    var body: some View {
        SearchViewControllerRepresentable()
            .ignoresSafeArea()
    }
}

struct SearchViewControllerRepresentable: UIViewControllerRepresentable {

    func makeUIViewController(
        context: Context
    ) -> UINavigationController {
        let searchVC = SearchViewController()

        let navigationController = UINavigationController(
            rootViewController: searchVC
        )

        return navigationController
    }

    func updateUIViewController(
        _ uiViewController: UINavigationController,
        context: Context
    ) {
        
    }
}

#Preview {
    HomeView()
}
