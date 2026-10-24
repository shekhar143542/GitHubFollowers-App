import UIKit
import GitHubNetworking

final class FollowersViewController: UIViewController {

    private let username: String
    private let api = GitHubAPIClient()

    private var followers: [GitHubUser] = []

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, GitHubUser>!

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
        fetchFollowers()
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

    private func applySnapshot(
        using followers: [GitHubUser]
    ) {
        var snapshot =
            NSDiffableDataSourceSnapshot<Int, GitHubUser>()

        snapshot.appendSections([0])
        snapshot.appendItems(followers)

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func fetchFollowers() {
        Task {
            do {
                let fetchedFollowers = try await api.fetchFollowers(
                    username: username,
                    page: 1
                )

                followers = fetchedFollowers
                applySnapshot(using: followers)

                if followers.isEmpty {
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

    private func showAlert(
        title: String,
        message: String
    ) {
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

extension FollowersViewController:
    UICollectionViewDelegateFlowLayout {

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
}

