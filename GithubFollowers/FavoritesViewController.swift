
import UIKit
import SwiftUI
import GitHubNetworking

final class FavoritesViewController: UIViewController {

    private var favorites: [FavoriteUser] = []

    private let tableView = UITableView(
        frame: .zero,
        style: .plain
    )

    private let emptyStateLabel = UILabel()

    private var dataSource: UITableViewDiffableDataSource<Int, FavoriteUser>!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Favorites"
        view.backgroundColor = .systemBackground

        configureTableView()
        configureEmptyStateLabel()
        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFavorites()
    }

    //Table View Setup

    private func configureTableView() {
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.rowHeight = 70

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            tableView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            tableView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            tableView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])
    }

    //Empty State

    private func configureEmptyStateLabel() {
        emptyStateLabel.text = """
        No Favorites
        Add one on the profile screen.
        """
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.font = .systemFont(
            ofSize: 18,
            weight: .medium
        )
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true

        view.addSubview(emptyStateLabel)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            emptyStateLabel.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
            emptyStateLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor,
                constant: 24
            ),
            emptyStateLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -24
            )
        ])
    }

    //Diffable Data Source

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Int, FavoriteUser>(
            tableView: tableView
        ) { (tableView, indexPath, favorite) -> UITableViewCell? in

            let cell = UITableViewCell(
                style: .subtitle,
                reuseIdentifier: nil
            )

            cell.textLabel?.text = favorite.login
            cell.textLabel?.font = .systemFont(
                ofSize: 17,
                weight: .semibold
            )

            cell.detailTextLabel?.text = favorite.htmlURL.absoluteString
            cell.detailTextLabel?.textColor = .secondaryLabel

            cell.accessoryType = .disclosureIndicator

            cell.imageView?.image = UIImage(
                systemName: "person.crop.circle.fill"
            )
            cell.imageView?.tintColor = .systemGreen

            let avatarURL = favorite.avatarURL

            Task { @MainActor in
                if let image = try? await ImageCacheManager.shared.getImage(
                    for: avatarURL
                ) {
                    guard
                        let currentIndexPath = tableView.indexPath(for: cell),
                        currentIndexPath == indexPath
                    else {
                        return
                    }

                    cell.imageView?.image = image
                    cell.setNeedsLayout()
                }
            }

            return cell
        }
    }

    //Load Favorites

    private func loadFavorites() {
        favorites = FavoritesManager.shared.getFavorites()
        updateUI(with: favorites)
    }

    private func updateUI(with favorites: [FavoriteUser]) {
        emptyStateLabel.isHidden = !favorites.isEmpty
        tableView.isHidden = favorites.isEmpty

        var snapshot = NSDiffableDataSourceSnapshot<Int, FavoriteUser>()
        snapshot.appendSections([0])
        snapshot.appendItems(favorites)

        dataSource.apply(
            snapshot,
            animatingDifferences: true
        )
    }
}

// Table View Delegate

extension FavoritesViewController: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let favorite = dataSource.itemIdentifier(for: indexPath) else {
            return
        }

        // Open the selected user's profile.
        let profileView = ProfileView(
            username: favorite.login
        )

        let hostingController = UIHostingController(
            rootView: profileView
        )

        hostingController.title = "Profile"

        navigationController?.pushViewController(
            hostingController,
            animated: true
        )
    }

    // Swipe to Delete

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {

        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] _, _, completionHandler in

            guard let self else {
                completionHandler(false)
                return
            }

            guard let favorite = self.dataSource.itemIdentifier(
                for: indexPath
            ) else {
                completionHandler(false)
                return
            }

            // Remove the favorite from persistent storage.
            FavoritesManager.shared.removeFavorite(favorite)

            self.favorites.removeAll {
                $0.id == favorite.id
            }

            // Update the displayed list.
            var snapshot = self.dataSource.snapshot()
            snapshot.deleteItems([favorite])

            self.dataSource.apply(
                snapshot,
                animatingDifferences: true
            )

            // Show the empty state if no favorites remain.
            self.emptyStateLabel.isHidden = !self.favorites.isEmpty
            self.tableView.isHidden = self.favorites.isEmpty

            completionHandler(true)
        }

        deleteAction.image = UIImage(systemName: "trash")

        return UISwipeActionsConfiguration(
            actions: [deleteAction]
        )
    }
}
