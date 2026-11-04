import UIKit
import GitHubNetworking

final class SearchViewController: UIViewController {

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
        configureDismissKeyboardTapGesture()
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
        usernameTextField.delegate = self
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
        let mainStack = UIStackView(
            arrangedSubviews: [
                logoImageView,
                titleLabel,
                usernameTextField,
                getFollowersButton
            ]
        )

        mainStack.axis = .vertical
        mainStack.alignment = .fill
        mainStack.distribution = .fill
        mainStack.spacing = 24

        mainStack.setCustomSpacing(8, after: logoImageView)
        mainStack.setCustomSpacing(48, after: titleLabel)

        view.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        let topConstraint = mainStack.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor,
            constant: 80
        )
        topConstraint.priority = UILayoutPriority(999)

        let logoHeight = logoImageView.heightAnchor.constraint(equalToConstant: 220)
        logoHeight.priority = UILayoutPriority(900)

        NSLayoutConstraint.activate([
            topConstraint,

            mainStack.topAnchor.constraint(
                greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 24
            ),

            mainStack.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24
            ),

            mainStack.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24
            ),

            mainStack.bottomAnchor.constraint(
                lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor,
                constant: -24
            ),

            logoHeight,
            logoImageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            titleLabel.heightAnchor.constraint(equalToConstant: 40),

            usernameTextField.heightAnchor.constraint(equalToConstant: 64),

            getFollowersButton.heightAnchor.constraint(equalToConstant: 76)
        ])
    }

    private func configureDismissKeyboardTapGesture() {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func getFollowersTapped() {
        usernameTextField.resignFirstResponder()

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

        let followersVC = FollowersViewController(
            username: username
        )

        followersVC.hidesBottomBarWhenPushed = true

        navigationController?.pushViewController(
            followersVC,
            animated: true
        )
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

extension SearchViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        getFollowersTapped()
        return true
    }
}

extension SearchViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        if let touchedView = touch.view {
            if touchedView.isDescendant(of: usernameTextField) || touchedView.isDescendant(of: getFollowersButton) {
                return false
            }
        }
        return true
    }
}

#Preview {
    SearchViewController()
}
