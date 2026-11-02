
import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTabs()
    }

    private func configureTabs() {

        let searchVC = SearchViewController()
        searchVC.title = "Search"

        let favoritesVC = FavoritesViewController()
        favoritesVC.title = "Favorites"

        let searchNavigationController = UINavigationController(
            rootViewController: searchVC
        )

        let favoritesNavigationController = UINavigationController(
            rootViewController: favoritesVC
        )

        searchNavigationController.tabBarItem = UITabBarItem(
            title: "Search",
            image: UIImage(systemName: "magnifyingglass"),
            tag: 0
        )

        favoritesNavigationController.tabBarItem = UITabBarItem(
            title: "Favorites",
            image: UIImage(systemName: "star.fill"),
            tag: 1
        )

        viewControllers = [
            searchNavigationController,
            favoritesNavigationController
        ]

        selectedIndex = 0
    }
}
