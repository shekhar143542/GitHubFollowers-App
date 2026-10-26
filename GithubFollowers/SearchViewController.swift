
import UIKit
import GitHubNetworking

final class SearchViewController: UIViewController {
    
    
    private let api = GitHubAPIClient()
    private var isFetching = false

    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let usernameTextField = UITextField()
    private let getFollowersButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        configureLogo()
        configureTitle()
        configureTextField()
        configureButton()
        configureLayout()
    }

    private func configureView() {
        view.backgroundColor = .systemBackground
    }

    private func configureLogo() {
        logoImageView.image = UIImage(
            systemName: "person.3.fill"
        )
        logoImageView.tintColor = .label
        logoImageView.contentMode = .scaleAspectFit
    }

    private func configureTitle() {
        titleLabel.text = "GitHub Followers"
        titleLabel.font = .systemFont(
            ofSize: 28,
            weight: .bold
        )
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
    }

    private func configureTextField() {
        usernameTextField.placeholder = "Enter GitHub username"
        usernameTextField.borderStyle = .roundedRect
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
            ofSize: 18,
            weight: .semibold
        )

        getFollowersButton.backgroundColor = .label
        getFollowersButton.setTitleColor(
            .systemBackground,
            for: .normal
        )

        getFollowersButton.layer.cornerRadius = 12

        getFollowersButton.addTarget(
            self,
            action: #selector(getFollowersTapped),
            for: .touchUpInside
        )
    }

    private func configureLayout() {
        let stackView = UIStackView(
            arrangedSubviews: [
                logoImageView,
                titleLabel,
                usernameTextField,
                getFollowersButton
            ]
        )

        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill

        view.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(
                equalToConstant: 80
            ),

            getFollowersButton.heightAnchor.constraint(
                equalToConstant: 52
            ),

            stackView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24
            ),

            stackView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24
            ),

            stackView.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor
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
