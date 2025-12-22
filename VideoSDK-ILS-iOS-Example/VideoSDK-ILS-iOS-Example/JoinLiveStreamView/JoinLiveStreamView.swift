//
//  JoinLiveStreamView.swift
//  VideoSDK-ILS-iOS-Example
//
//  Created by Deep Bhupatkar on 18/01/25.
//

import AVFoundation
import Foundation
import SwiftUI
import VideoSDKRTC

#warning("Provide either auth-url to start the meeting")
let AUTH_TOKEN: String = "YOUR_TOKEN"

struct JoinLiveStreamView: View {
    @State var streamId: String = ""
    @State var name: String = ""
    @State private var isMicEnabled: Bool = false
    @StateObject private var cameraPreview = CameraPreviewModel()
    @State private var showActionSheet = false
    @State private var audioDeviceList: [String] = []
    @State private var selectedCameraMode: AVCaptureDevice.Position = .front
    @State private var selectedAudioDevice: String?
    @State private var isNavigating = false
    @State private var isCameraEnabled: Bool = true

    // Colors and constants
    private let accentColor = Color(red: 0.2, green: 0.5, blue: 1.0)
    private let backgroundColor = Color(red: 0.98, green: 0.98, blue: 0.98)
    @State private var mode: Mode
    var role: UserRole

    init(selectedRole: UserRole) {
        self.role = selectedRole
        self.mode = selectedRole == .HOST ? .SEND_AND_RECV : .RECV_ONLY

        if streamId.isEmpty {
            createRoom()
        }
    }

    func createRoom() {
        let urlString = "https://api.videosdk.live/v2/rooms"
        let session = URLSession.shared
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(AUTH_TOKEN, forHTTPHeaderField: "Authorization")

        session.dataTask(
            with: request,
            completionHandler: {
                (data: Data?, response: URLResponse?, error: Error?) in
                if let data = data,
                    String(data: data, encoding: .utf8) != nil
                {
                    do {
                        let dataArray = try JSONDecoder().decode(
                            RoomStruct.self,
                            from: data
                        )
                        self.streamId = dataArray.roomID!
                    } catch {
                        print("error while create room: \(error)")
                    }
                }
            }
        ).resume()
    }

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    // Camera Preview
                    GeometryReader { geometry in
                        ZStack {
                            CameraPreviewView(
                                session: cameraPreview.session
                            )
                            .frame(height: 300)
                            .cornerRadius(16)
                            .overlay(
                                Group {
                                    if !isCameraEnabled {
                                        ZStack {
                                            Color.gray.opacity(2.0)
                                        }
                                        .cornerRadius(16)
                                    }
                                }
                            )

                            VStack {
                                Spacer()

                                // Bottom controls row
                                HStack {
                                    // Microphone Button
                                    Button(action: {
                                        if isMicEnabled {
                                            isMicEnabled = false
                                        } else {
                                            isMicEnabled = true
                                        }
                                    }) {
                                        Image(
                                            systemName: isMicEnabled
                                                ? "mic.fill"
                                                : "mic.slash.fill"
                                        )
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(
                                            Circle().fill(
                                                Color.black.opacity(
                                                    0.6
                                                )
                                            )
                                        )
                                    }
                                    .frame(width: 50, height: 50)

                                    // Camera Toggle Button
                                    Button(action: {
                                        isCameraEnabled.toggle()
                                        if isCameraEnabled {
                                            cameraPreview
                                                .startSession()
                                        } else {
                                            cameraPreview
                                                .stopSession()
                                        }
                                    }) {
                                        Image(
                                            systemName:
                                                isCameraEnabled
                                                ? "video.fill"
                                                : "video.slash.fill"
                                        )
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(
                                            Circle().fill(
                                                Color.black.opacity(
                                                    0.6
                                                )
                                            )
                                        )
                                    }
                                    .frame(width: 50, height: 50)
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 5)
                            }
                        }
                    }
                }
                .padding()
                .frame(width: 250, height: 300, alignment: .top)
                //
                Spacer()
                //
                VStack(spacing: 15) {
                    // Stream ID Field
                    CustomTextField(
                        text: $streamId,
                        placeholder: "Enter Stream ID",
                        systemImage: "number"
                    )
                    // Name Field
                    CustomTextField(
                        text: $name,
                        placeholder: "Enter Your Name",
                        systemImage: "person"
                    )

                    if role == .HOST {
                        NavigationLink(
                            destination: LiveStreamView(
                                streamId: streamId,
                                userName: name.isEmpty ? "Guest" : name,
                                mode: mode
                            )
                            .navigationBarBackButtonHidden(true)
                        ) {
                            ActionButton(
                                title: "Start Stream",
                                color: .indigo
                            )
                        }
                    } else if !streamId.isEmpty {
                        NavigationLink(
                            destination: LiveStreamView(
                                streamId: streamId,
                                userName: name.isEmpty ? "Guest" : name,
                                mode: mode
                            )
                            .navigationBarBackButtonHidden(true)
                        ) {
                            ActionButton(
                                title: "Join Stream",
                                color: .indigo
                            )
                        }
                    }
                }
                //
                Spacer()
            }
            .onAppear {
                cameraPreview.checkPermissionsAndSetupSession()
                isCameraEnabled = false
            }
            .onDisappear {
                cameraPreview.stopSession()
            }
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
