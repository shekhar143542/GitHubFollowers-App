
import UIKit
import GitHubNetworking

final class SearchViewController: UIViewController {
    
    
    private let api = GitHubAPIClient()
    private var isFetching = false

    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let usernameTextField = UITextField()
    private let bottomTabBar = UITabBar()
    private let getFollowersButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        configureLogo()
        configureTitle()
        configureTextField()
        configureButton()
        configureLayout()
        configureTabBar() 
    }
    
    
    
    private func configureTabBar() {
        let searchItem = UITabBarItem(
            title: "Search",
            image: UIImage(systemName: "magnifyingglass"),
            tag: 0
        )

        let favoritesItem = UITabBarItem(
            title: "Favorites",
            image: UIImage(systemName: "star.fill"),
            tag: 1
        )

        bottomTabBar.items = [searchItem, favoritesItem]
        bottomTabBar.selectedItem = searchItem
        bottomTabBar.tintColor = .systemGreen
        bottomTabBar.unselectedItemTintColor = .secondaryLabel

        view.addSubview(bottomTabBar)
        bottomTabBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bottomTabBar.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            bottomTabBar.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            bottomTabBar.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            )
        ])
    }


    private func configureView() {
        view.backgroundColor = .systemBackground
    }

    private func configureLogo() {

        logoImageView.image = UIImage(named: "GitHub-Logo-followers")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.clipsToBounds = true
    }

    private func configureTitle() {
        titleLabel.text = "Followers"
        titleLabel.font = .systemFont(
            ofSize: 28,
            weight: .bold
        )
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
    }


    private func configureTextField() {
        usernameTextField.placeholder = "Enter a username"
        usernameTextField.font = .systemFont(ofSize: 20)
        usernameTextField.textAlignment = .center
        usernameTextField.textColor = .label
        usernameTextField.tintColor = .systemGreen
        usernameTextField.backgroundColor = .systemBackground

        usernameTextField.layer.borderWidth = 2
        usernameTextField.layer.borderColor = UIColor.darkGray.cgColor
        usernameTextField.layer.cornerRadius = 12

        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no
        usernameTextField.returnKeyType = .search
        usernameTextField.clearButtonMode = .whileEditing
        usernameTextField.accessibilityLabel = "GitHub username"
    }



    private func configureButton() {
        getFollowersButton.setTitle(
            "Get Followers",
            for: .normal
        )

        getFollowersButton.titleLabel?.font = .systemFont(
            ofSize: 20,
            weight: .semibold
        )

        getFollowersButton.backgroundColor = .systemGreen
        getFollowersButton.setTitleColor(.white, for: .normal)
        getFollowersButton.layer.cornerRadius = 16

        getFollowersButton.addTarget(
            self,
            action: #selector(getFollowersTapped),
            for: .touchUpInside
        )
    }



    private func configureLayout() {
        let headerStack = UIStackView(
            arrangedSubviews: [
                logoImageView,
                titleLabel
            ]
        )

        headerStack.axis = .vertical
        headerStack.alignment = .center
        headerStack.spacing = 8

        view.addSubview(headerStack)
        view.addSubview(usernameTextField)
        view.addSubview(getFollowersButton)

        headerStack.translatesAutoresizingMaskIntoConstraints = false
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        getFollowersButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 120
            ),
            headerStack.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            logoImageView.heightAnchor.constraint(
                equalToConstant: 220
            ),
            logoImageView.widthAnchor.constraint(
                equalToConstant: 280
            ),

            titleLabel.heightAnchor.constraint(
                equalToConstant: 40
            ),

            usernameTextField.topAnchor.constraint(
                equalTo: headerStack.bottomAnchor,
                constant: 50
            ),
            usernameTextField.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24
            ),
            usernameTextField.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24
            ),
            usernameTextField.heightAnchor.constraint(
                equalToConstant: 64
            ),

            getFollowersButton.leadingAnchor.constraint(
                equalTo: usernameTextField.leadingAnchor
            ),
            getFollowersButton.trailingAnchor.constraint(
                equalTo: usernameTextField.trailingAnchor
            ),
            getFollowersButton.heightAnchor.constraint(
                equalToConstant: 76
            ),
            getFollowersButton.bottomAnchor.constraint(
                lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -140
            )
        ])
    }

  
    @objc private func getFollowersTapped() {
        let username = usernameTextField.text?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        guard !username.isEmpty else {
            showAlert(
                title: "Username Required",
                message: "Please enter a GitHub username."
            )
            return
        }

        guard !isFetching else {
            return
        }

        isFetching = true
        getFollowersButton.isEnabled = false

        Task {
            defer {
                isFetching = false
                getFollowersButton.isEnabled = true
            }

            do {
                // Verify that this GitHub user exists.
                _ = try await api.fetchUser(username: username)

                // Create the Followers screen with this username.
                let followersVC = FollowersViewController(
                    username: username
                )

                // Navigate to the Followers screen.
                navigationController?.pushViewController(
                    followersVC,
                    animated: true
                )

            } catch GitHubAPIError.userNotFound {
                showAlert(
                    title: "User Not Found",
                    message: "No GitHub user exists with that username."
                )

            } catch GitHubAPIError.rateLimitExceeded {
                showAlert(
                    title: "API Limit Reached",
                    message: "GitHub has temporarily limited requests. Please try again later."
                )

            } catch {
                showAlert(
                    title: "Request Failed",
                    message: "Unable to verify this GitHub user. Please try again."
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
            UIAlertAction(
                title: "OK",
                style: .default
            )
        )

        present(alert, animated: true)
    }
}


#Preview {
    SearchViewController()
}
