
import SwiftUI
import UIKit
import GitHubNetworking

struct RepositoriesView: View {

    @StateObject private var viewModel: RepositoriesViewModel

    init(username: String) {
        _viewModel = StateObject(
            wrappedValue: RepositoriesViewModel(username: username)
        )
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.repositories.isEmpty {
                ProgressView("Loading repositories...")
            } else if let errorMessage = viewModel.errorMessage,
                      viewModel.repositories.isEmpty {
                ContentUnavailableView(
                    "Unable to Load Repositories",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else if viewModel.repositories.isEmpty {
                ContentUnavailableView(
                    "No Repositories",
                    systemImage: "book.closed",
                    description: Text(
                        "This user has no public repositories."
                    )
                )
            } else {
                repositoryList
            }
        }
        .task {
            await viewModel.loadRepositories()
        }
        .navigationTitle("Repositories")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var repositoryList: some View {
        List {
            ForEach(viewModel.repositories) { repository in
                VStack(alignment: .leading, spacing: 8) {
                    Text(repository.name)
                        .font(.headline)

                    if let description = repository.description,
                       !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 16) {
                        if let language = repository.language {
                            Label(
                                language,
                                systemImage: "circle.fill"
                            )
                            .font(.caption)
                        }

                        Label(
                            "\(repository.stargazersCount)",
                            systemImage: "star"
                        )
                        .font(.caption)

                        Spacer()

                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.open(repository.htmlURL)
                }
                .onAppear {
                    if repository.id == viewModel.repositories.last?.id {
                        Task {
                            await viewModel.loadRepositories()
                        }
                    }
                }
            }

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading more repositories...")
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }

            if let errorMessage = viewModel.errorMessage,
               !viewModel.repositories.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
        }
        .listStyle(.insetGrouped)
    }
}
