
import UIKit
import GitHubNetworking

final class FollowersViewController: UIViewController {

    private let username: String
    private let api = GitHubAPIClient()

    private var followers: [GitHubUser] = []
    
    //filtering properties
    private var filteredFollowers: [GitHubUser] = []
    private var isFiltering: Bool = false

    private let searchController = UISearchController(
        searchResultsController: nil
    )

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

        title = "\(username)'s Followers"
        view.backgroundColor = .systemBackground

        configureCollectionView()
        configureDataSource()
        configureSearchController()

        loadFollowers(page: currentPage)
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
    
    //applying snapshot to store all the followers
    private func applySnapshot(using users: [GitHubUser]) {
        var snapshot =
            NSDiffableDataSourceSnapshot<Int, GitHubUser>()

        snapshot.appendSections([0])
        snapshot.appendItems(users)

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func loadFollowers(page: Int) {
        guard !isLoadingPage && hasMoreFollowers else {
            return
        }

        isLoadingPage = true

        Task {
            defer {
                isLoadingPage = false
            }

            do {
                let fetchedFollowers = try await api.fetchFollowers(
                    username: username,
                    page: page
                )

                // Keep the followers already loaded.
                followers.append(contentsOf: fetchedFollowers)

                if isFiltering {
                    filterFollowers(searchText: searchController.searchBar.text ?? "")
                } else {
                    applySnapshot(using: followers)
                }

                // A short page means we reached the end.
                hasMoreFollowers = fetchedFollowers.count == 100

                // Remember the next page to request.
                currentPage = page + 1

                if page == 1 && followers.isEmpty {
                    showAlert(
                        title: "No Followers",
                        message: "This user doesn't have any followers yet."
                    )
                }

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
        // Start loading when we approach the last 10 followers.
        let threshold = max(followers.count - 10, 0)

        if indexPath.item >= threshold {
            loadFollowers(page: currentPage)
        }
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
