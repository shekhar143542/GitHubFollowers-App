//
//  HomeView.swift
//  GithubFollowers
//
//  Created by Kubbireddy Soma Chinna Shekhar on 22/10/26.
//


import SwiftUI

struct HomeView: View {
    @State private var username = ""
    @State private var showError = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundStyle(.primary)

            Text("GitHub Followers")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Discover developers and explore their followers.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Enter GitHub username", text: $username)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button {
                if username.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty {
                    showError = true
                } else {
                    showError = false
                }
            } label: {
                Text("Get Followers")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
            }

            Spacer()
        }
        .padding(24)
        .alert("Username Required", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a GitHub username to continue.")
        }
    }
}

#Preview {
    HomeView()
}

