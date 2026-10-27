import UIKit
import GitHubNetworking
import SwiftUI

final class FollowersViewController: UIViewController {

    private let username: String
    private let api = GitHubAPIClient()

    private var followers: [GitHubUser] = []

    // filtering properties
    private var filteredFollowers: [GitHubUser] = []
    private var isFiltering: Bool = false

    private let searchController = UISearchController(
        searchResultsController: nil
    )

    private let emptyStateLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // Pagination state
    private var currentPage = 1
    private var hasMoreFollowers = true
    private var isLoadingPage = false

    private var collectionView: UICollectionView!
    private var dataSource:
        UICollectionViewDiffableDataSource<Int, GitHubUser>!

    init(username: String) {
        self.username = username
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewController()
        configureCollectionView()
        configureDataSource()
        configureEmptyStateLabel()
        configureActivityIndicator()
        configureSearchController()

        loadFollowers(page: currentPage)
    }

    private func configureViewController() {
        title = "\(username)'s Followers"
        view.backgroundColor = .systemBackground

        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        navigationItem.rightBarButtonItem = addButton
    }

    @objc private func addButtonTapped() {
        Task {
            do {
                let user = try await api.fetchUser(username: username)
                FavoritesManager.shared.addFavorite(user)
                showAlert(
                    title: "Success!",
                    message: "You have successfully favorited \(username) 🎉"
                )
            } catch GitHubAPIError.userNotFound {
                showAlert(
                    title: "User Not Found",
                    message: "The GitHub user could not be found."
                )
            } catch GitHubAPIError.rateLimitExceeded {
                showAlert(
                    title: "API Limit Reached",
                    message: "GitHub rate limit exceeded. Please try again later."
                )
            } catch {
                showAlert(
                    title: "Unable to Favorite",
                    message: "Something went wrong while favoriting this user."
                )
            }
        }
    }

    private func updateEmptyState(
        displayedUsers: [GitHubUser]
    ) {
        if displayedUsers.isEmpty && !isLoadingPage {
            emptyStateLabel.isHidden = false

            if isFiltering {
                emptyStateLabel.text = "No Matching Followers"
            } else {
                emptyStateLabel.text = "No Followers"
            }
        } else {
            emptyStateLabel.isHidden = true
        }
    }

    private func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search followers"

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        definesPresentationContext = true
    }

    private func configureCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(
            top: 16,
            left: 16,
            bottom: 16,
            right: 16
        )

        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )

        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.register(
            FollowerCell.self,
            forCellWithReuseIdentifier: FollowerCell.reuseIdentifier
        )

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            collectionView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            collectionView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])

        collectionView.delegate = self
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, GitHubUser>(
            collectionView: collectionView
        ) { collectionView, indexPath, follower in

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FollowerCell.reuseIdentifier,
                for: indexPath
            ) as! FollowerCell

            cell.configure(with: follower)
            return cell
        }
    }

    private func applySnapshot(using users: [GitHubUser]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, GitHubUser>()
        snapshot.appendSections([0])

        // Filter duplicates by id to ensure DiffableDataSource identifiers remain unique
        var seenIDs = Set<Int>()
        let uniqueUsers = users.filter { seenIDs.insert($0.id).inserted }
        snapshot.appendItems(uniqueUsers)

        dataSource.apply(
            snapshot,
            animatingDifferences: true
        )

        updateEmptyState(displayedUsers: uniqueUsers)
    }

    private func loadFollowers(page: Int) {
        guard !isLoadingPage && hasMoreFollowers else {
            return
        }

        isLoadingPage = true
        if page == 1 && followers.isEmpty {
            activityIndicator.startAnimating()
        }

        Task {
            defer {
                isLoadingPage = false
                activityIndicator.stopAnimating()
            }

            do {
                let fetchedFollowers = try await api.fetchFollowers(
                    username: username,
                    page: page
                )

                // Append newly fetched followers
                for follower in fetchedFollowers {
                    if !followers.contains(where: { $0.id == follower.id }) {
                        followers.append(follower)
                    }
                }

                if isFiltering {
                    filterFollowers(searchText: searchController.searchBar.text ?? "")
                } else {
                    applySnapshot(using: followers)
                }

                // A short page means we reached the end.
                hasMoreFollowers = fetchedFollowers.count == 100

                // Remember the next page to request.
                currentPage = page + 1

            } catch GitHubAPIError.userNotFound {
                showAlert(
                    title: "User Not Found",
                    message: "The GitHub user could not be found."
                )

            } catch GitHubAPIError.rateLimitExceeded {
                showAlert(
                    title: "API Limit Reached",
                    message: "Please wait before making more GitHub requests."
                )

            } catch {
                showAlert(
                    title: "Unable to Load Followers",
                    message: "Something went wrong while loading followers."
                )
            }
        }
    }

    private func configureEmptyStateLabel() {
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
                equalTo: view.safeAreaLayoutGuide.centerYAnchor
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

    private func configureActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .systemGreen

        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            activityIndicator.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor
            )
        ])
    }

    private func filterFollowers(searchText: String) {
        let text = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if text.isEmpty {
            isFiltering = false
            filteredFollowers = []
            applySnapshot(using: followers)
            return
        }

        isFiltering = true

        filteredFollowers = followers.filter {
            $0.login.localizedCaseInsensitiveContains(text)
        }

        applySnapshot(using: filteredFollowers)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "OK", style: .default)
        )

        present(alert, animated: true)
    }
}

extension FollowersViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let totalSpacing: CGFloat = 32 + 16
        guard collectionView.bounds.width > totalSpacing else {
            return CGSize(width: 80, height: 120)
        }
        let itemWidth = (
            collectionView.bounds.width - totalSpacing
        ) / 3

        return CGSize(width: itemWidth, height: 120)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        // If filtering, don't paginate
        guard !isFiltering, hasMoreFollowers, !isLoadingPage else {
            return
        }

        // Start loading when we approach the last 10 followers.
        let threshold = max(followers.count - 10, 0)

        if indexPath.item >= threshold {
            loadFollowers(page: currentPage)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let follower = dataSource.itemIdentifier(
            for: indexPath
        ) else {
            return
        }

        let profileView = ProfileView(
            username: follower.login,
            onGetFollowers: { [weak self] username in
                guard let self else { return }

                let followersVC = FollowersViewController(
                    username: username
                )

                self.navigationController?.pushViewController(
                    followersVC,
                    animated: true
                )
            }
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
}

extension FollowersViewController: UISearchResultsUpdating {

    func updateSearchResults(
        for searchController: UISearchController
    ) {
        filterFollowers(
            searchText: searchController.searchBar.text ?? ""
        )
    }
}
