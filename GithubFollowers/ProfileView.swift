
import SwiftUI
import GitHubNetworking

struct ProfileView: View {

    @StateObject private var viewModel: ProfileViewModel
    
    var onGetFollowers: ((String) -> Void)?
    @State private var isFavorite = false

    init(
        username: String,
        onGetFollowers: ((String) -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: ProfileViewModel(username: username)
        )

        self.onGetFollowers = onGetFollowers
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.user == nil {
                ProgressView("Loading profile...")
            } else if let user = viewModel.user {
                profileContent(user: user)
            } else if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView(
                    "Unable to Load Profile",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text(errorMessage)
                )
            } else {
                ProgressView("Loading profile...")
            }
        }
        .task {
            await viewModel.loadProfile()

            if let user = viewModel.user {
                updateFavoriteStatus(for: user)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func profileContent(user: GitHubUser) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                AsyncImage(url: user.avatarURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())

                Text(user.name ?? user.login)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("@\(user.login)")
                    .foregroundStyle(.secondary)

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                HStack(spacing: 40) {
                    statistic(
                        title: "Followers",
                        value: user.followers
                    )

                    statistic(
                        title: "Following",
                        value: user.following
                    )
                }
                .padding(.top, 8)
                
                Button {
                    if isFavorite {
                        if let favorite = FavoritesManager.shared
                            .getFavorites()
                            .first(where: { $0.id == user.id }) {
                            FavoritesManager.shared.removeFavorite(favorite)
                        }
                    } else {
                        FavoritesManager.shared.addFavorite(user)
                    }

                    updateFavoriteStatus(for: user)
                } label: {
                    Label(
                        isFavorite ? "Added to Favorites" : "Add to Favorites",
                        systemImage: isFavorite ? "star.fill" : "star"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(isFavorite ? Color.green : Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                
                Button {
                    onGetFollowers?(user.login)
                } label: {
                    Text("Get Followers")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
    
    private func updateFavoriteStatus(for user: GitHubUser) {
        isFavorite = FavoritesManager.shared
            .getFavorites()
            .contains { $0.id == user.id }
    }

    private func statistic(
        title: String,
        value: Int?
    ) -> some View {
        VStack(spacing: 6) {
            Text("\(value ?? 0)")
                .font(.title3)
                .fontWeight(.semibold)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}



