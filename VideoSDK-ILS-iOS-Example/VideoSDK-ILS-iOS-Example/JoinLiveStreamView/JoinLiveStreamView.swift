//
//  JoinLiveStreamView.swift
//  VideoSDK-ILS-iOS-Example
//
//  Created by Deep Bhupatkar on 18/01/25.
//


import SwiftUI
import Foundation
import VideoSDKRTC
import AVFoundation

struct JoinLiveStreamView: View {
    @State var meetingId: String
    @State var name: String
    @State private var isMicEnabled: Bool = true
    @State private var isFrontCamera: Bool = true
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
    
    @State private var mode: Mode = .SEND_AND_RECV // Store mode based on role
    var role: String // "Create Room", "Host", or "Audience"

    
    init(meetingId: String? = nil, name: String? = nil, role: String) {
          self.meetingId = meetingId ?? ""
          self.name = name ?? ""
          self.role = role
          // Set mode based on role
          switch role {
          case "Create Room", "Host":
              _mode = State(initialValue: .SEND_AND_RECV)
          case "Audience":
              _mode = State(initialValue: .RECV_ONLY)
          default:
              _mode = State(initialValue: .SEND_AND_RECV)
          }
      }
    
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [backgroundColor, Color.black]),
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                    
                        //Precall View and Controlls for that
                        ZStack {
                            VStack {
                                // Camera Preview
                                GeometryReader { geometry in
                                    ZStack {
                                        CameraPreviewView(session: cameraPreview.session)
                                            .frame(height: 350)
                                            .cornerRadius(16)
                                            .overlay(
                                                Group {
                                                    if !isCameraEnabled {
                                                        ZStack {
                                                            Color.indigo.opacity(2.0)
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
                                                }) {
                                                    Image(systemName: isMicEnabled ? "mic.fill" : "mic.slash.fill")
                                                        .foregroundColor(.white)
                                                        .padding(11)
                                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                                }
                                                
                                                // Camera Toggle Button
                                                Button(action: {
                                                    isCameraEnabled.toggle()
                                                    if isCameraEnabled {
                                                        cameraPreview.startSession()
                                                    } else {
                                                        cameraPreview.stopSession()
                                                    }
                                                }) {
                                                    Image(systemName: isCameraEnabled ? "video.fill" : "video.slash.fill")
                                                        .foregroundColor(.white)
                                                        .padding(11)
                                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                                }
                                            }
                                            .padding(.horizontal)
                                            .padding(.bottom, 5)
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        .frame(width: 300, height: 250) // Set desired width here
                        .padding(.horizontal)

                        // Input Fields
                        VStack(spacing: 16) {
                            // Add padding before this VStack
                            Spacer()
                                .frame(height: 120) // Adjust height for desired spacing

                            if role != "Create Room" {
                                
                                // Meeting ID Field
                                CustomTextField(
                                    text: $meetingId,
                                    placeholder: "Enter Meeting ID",
                                    systemImage: "number"
                                )
                            }
                            
                            // Name Field
                            CustomTextField(
                                text: $name,
                                placeholder: "Enter Your Name",
                                systemImage: "person"
                            )
                        }  // White text for contrast

                        .padding(.top)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            if role == "Create Room" {
                                NavigationLink(
                                    destination: LiveStreamView(
                                        userName: name.isEmpty ? "Guest" : name, mode: mode
                                    )
                                    .navigationBarBackButtonHidden(true)
                                ) {
                                    ActionButton(title: "Start Meeting", color: .indigo)
                                }
                            }
                            
                            else if !meetingId.isEmpty {
                                NavigationLink(
                                    destination: LiveStreamView(
                                        meetingId: meetingId,
                                        userName: name.isEmpty ? "Guest" : name, mode: mode
                                    )
                                    .navigationBarBackButtonHidden(true)
                                ) {
                                    ActionButton(title: "Join Meeting", color: .indigo)
                                }
                            }
                      
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 32)
                }
            }
            .onAppear {
                cameraPreview.checkPermissionsAndSetupSession()
                isCameraEnabled = false
            }
            .onDisappear {
                cameraPreview.stopSession()
            }
        }.navigationBarBackButtonHidden(true) // Hides the back button

    }

}


extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
