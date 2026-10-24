


import SwiftUI
import GitHubNetworking

struct NetworkingTestView: View {
    @State private var message = "Tap the button to test GitHub."

    var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .multilineTextAlignment(.center)

            Button("Fetch GitHub User") {
                Task {
                    do {
                        let api = GitHubAPIClient()
                        let user = try await api.fetchUser(
                            username: "octocat"
                        )

                        message = """
                        Success!
                        Username: \(user.login)
                        Name: \(user.name ?? "No name provided")
                        Followers: \(user.followers ?? 0)
                        """
                    } catch {
                        message = "Request failed: \(error)"
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    NetworkingTestView()
}

