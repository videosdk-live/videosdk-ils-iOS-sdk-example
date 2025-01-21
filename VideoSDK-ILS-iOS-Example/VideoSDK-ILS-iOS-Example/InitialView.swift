//
//  InitialView.swift
//  VideoSDK-ILS-iOS-Example
//
//  Created by Deep Bhupatkar on 18/01/25.
//

import SwiftUI
import VideoSDKRTC

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
                    NavigationLink(destination: JoinLiveStreamView(streamId: "", name: "", role: "Create Room" )) {
                        ActionButtonn(title: "Create Live Stream", icon: "person.fill")
                    }
                    
                    Text("---- OR ----")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    NavigationLink(destination: JoinLiveStreamView(streamId: "", name: "", role: "Host")) {
                        ActionButtonn(title: "Join as Host", icon: "person.fill")
                    }
                    
                    NavigationLink(destination: JoinLiveStreamView(streamId: "", name: "", role: "Audience")) {
                        ActionButtonn(title: "Join as Audience", icon: "person.fill")
                    }
                }
            }
            .navigationBarBackButtonHidden(false)
        }
        .padding(.horizontal)
    }
}

#Preview {
    InitialView()
}
