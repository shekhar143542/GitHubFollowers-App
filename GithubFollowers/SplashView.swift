//
//  SplashView.swift
//  GithubFollowers
//
//  Created by Kubbireddy Soma Chinna Shekhar on 22/10/26.
//


import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 65))
                    .foregroundStyle(.primary)

                Text("GitHub Followers")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Discover developers. Explore their work.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

//#Preview {
//    SplashView()
//}

