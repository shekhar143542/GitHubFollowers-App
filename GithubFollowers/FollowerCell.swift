
import UIKit
import GitHubNetworking

final class FollowerCell: UICollectionViewCell {

    static let reuseIdentifier = "FollowerCell"

    private let avatarImageView = UIImageView()
    private let usernameLabel = UILabel()

    // Identifies the image this cell is currently expecting.
    private var representedURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureAvatar()
        configureUsername()
        configureLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        // Prevent an old image from appearing for another user.
        representedURL = nil
                avatarImageView.image = UIImage(
            systemName: "person.crop.circle.fill"
        )
    }

    private func configureAvatar() {
        avatarImageView.image = UIImage(
            systemName: "person.crop.circle.fill"
        )
        avatarImageView.tintColor = .secondaryLabel
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 30
    }

    private func configureUsername() {
        usernameLabel.font = .systemFont(
            ofSize: 13,
            weight: .medium
        )
        usernameLabel.textAlignment = .center
        usernameLabel.numberOfLines = 1
        usernameLabel.lineBreakMode = .byTruncatingTail
    }

    private func configureLayout() {
        let stackView = UIStackView(
            arrangedSubviews: [avatarImageView, usernameLabel]
        )

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8

        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(
                equalToConstant: 60
            ),
            avatarImageView.heightAnchor.constraint(
                equalToConstant: 60
            ),
            stackView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 8
            ),
            stackView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 4
            ),
            stackView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -4
            ),
            stackView.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -8
            )
        ])
    }

    func configure(with follower: GitHubUser) {
        usernameLabel.text = follower.login

        // Show the placeholder while the image loads.
        avatarImageView.image = UIImage(
            systemName: "person.crop.circle.fill"
        )

        let url = follower.avatarURL
        representedURL = url

        Task {
            do {
                let image = try await ImageCacheManager.shared.getImage(
                    for: url
                )

                // Cells are reused, so ensure this is still
                // the correct image for the current follower.
                guard representedURL == url else {
                    return
                }

                avatarImageView.image = image

            } catch {
                // Keep the placeholder if image loading fails.
            }
        }
    }
}
