//
//  InitialView.swift
//  VideoSDK-ILS-iOS-Example
//
//  Created by Deep Bhupatkar on 18/01/25.
//

import SwiftUI
import VideoSDKRTCSwift

enum UserRole: String {
    case HOST = "Host"
    case AUDIENCE = "Audience"
}

struct InitialView: View {
    var body: some View {
        NavigationStack {
            // Buttons Stack
            VStack(spacing: 16) {
                Text("VideoSDK")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Interactive Live Streaming Example")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()

                VStack(spacing: 16) {
                    NavigationLink(
                        destination: JoinLiveStreamView(selectedRole: .HOST)
                    ) {
                        AppButton(
                            title: "Create Live Stream",
                        )
                    }

                    Text("---- OR ----")
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    NavigationLink(
                        destination: JoinLiveStreamView(selectedRole: .HOST)
                    ) {
                        AppButton(
                            title: "Join as Host",
                        )
                    }

                    NavigationLink(
                        destination: JoinLiveStreamView(selectedRole: .AUDIENCE)
                    ) {
                        AppButton(
                            title: "Join as Audience",
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    InitialView()
}
