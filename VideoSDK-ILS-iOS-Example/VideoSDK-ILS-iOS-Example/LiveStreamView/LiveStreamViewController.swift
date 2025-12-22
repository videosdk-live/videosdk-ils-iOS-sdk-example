//
//  LiveStreamViewController.swift
//  VideoSDK-ILS-iOS-Example
//
//  Created by Deep Bhupatkar on 18/01/25.
//

import EmojiPicker
import Foundation
import SwiftUI
import VideoSDKRTC
import WebRTC

class LiveStreamViewController: ObservableObject {
    var selectedEmoji: Emoji?
    // Add this property to store the sender's ID from the host request
    var requestFrom: String?

    @Published var meeting: Meeting? = nil
    @Published var meetingMode: Mode
    @Published var localParticipantView: VideoView? = nil
    @Published var participants: [Participant] = []
    @Published var localParticipant: Participant? = nil
    @Published var streamID: String
    @Published var nameOfParticipant: String
    @Published var participantVideoTracks: [String: RTCVideoTrack] = [:]
    @Published var participantMicStatus: [String: Bool] = [:]
    @Published var participantCameraStatus: [String: Bool] = [:]
    @Published var reactions: [String] = []
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showActionButtons = false

    @Published var isMicEnabled: Bool = true
    @Published var isCamEnabled: Bool = true

    init(streamID: String, nameOfParticipant: String, mode: VideoSDKRTC.Mode) {
        self.streamID = streamID
        self.nameOfParticipant = nameOfParticipant
        self.meetingMode = mode

        initialiseMeeting()
    }

    func initialiseMeeting() {
        if !AUTH_TOKEN.isEmpty {
            VideoSDK.config(token: AUTH_TOKEN)

            // Initialize the meeting
            let videoMediaTrack = try? VideoSDK.createCameraVideoTrack(
                encoderConfig: .h720p_w1280p,
                facingMode: .front,
                multiStream: false
            )
            meeting = VideoSDK.initMeeting(
                meetingId: self.streamID,
                participantId: "",
                participantName: self.nameOfParticipant,
                micEnabled: isMicEnabled,
                webcamEnabled: isCamEnabled,
                customCameraVideoStream: videoMediaTrack,
                mode: self.meetingMode
            )
            // Add event listeners and join the meeting
            meeting?.addEventListener(self)

            meeting?.join()
        } else {
            print("Please provide AUTH_TOKEN")
        }
    }

    func sendTheReaction(_ emoji: Emoji) {
        print("Sending reaction: \(emoji.value)")
        Task {
            do {
                try await self.meeting?.pubsub.publish(
                    topic: "REACTION",
                    message: emoji.value,
                    options: [:]
                )
            } catch {
                print("Error while sendTheReaction: \(error)")
            }
        }
    }

    func showHostRequestAlert(participantId: String, participantName: String) {
        self.alertTitle = "Host Request"
        self.alertMessage =
            "\(participantName) has requested to become the host. Do you accept?"
        self.showAlert = true
        self.showActionButtons = true
    }

    func sendTheHostRequest(_ participant: Participant) {
        let message = "Request for mode change your mode"
        let senderName = participants.first?.displayName ?? "Unknown"
        let senderId = participants.first?.id ?? "Unknown"
        let payload = [
            "receiverId": "\(participant.id)",
            "senderName": "\(senderName)",
            "senderId": "\(senderId)",
        ]
        Task {
            do {
                try await self.meeting?.pubsub.publish(
                    topic: "HOSTREQUESTED",
                    message: message,
                    options: [:],
                    payload: payload
                )
            } catch {
                print("Error while sending request to become host: \(error)")
            }
        }

    }

    func acceptHostChange() {
        let senderName = participants.first?.displayName ?? "Unknown"
        let recvID = requestFrom ?? "Unknown"
        let payload = [
            "receiverId": "\(recvID)",
            "accpeterName": "\(senderName)",
        ]
        Task {
            await meeting?.changeMode(.SEND_AND_RECV)
            do {
                try await self.meeting?.pubsub.publish(
                    topic: "ACK",
                    message: "ACCEPTED",
                    options: [:],
                    payload: payload
                )
            } catch {
                print("Error while acceptHostChange: \(error)")
            }
        }

    }

    func declineHostChange() {
        let senderName = participants.first?.displayName ?? "Unknown"
        let recvID = requestFrom ?? "Unknown"
        let payload = [
            "receiverId": "\(recvID)",
            "accpeterName": "\(senderName)",
        ]
        print("declineHostChange \(payload)")
        Task {
            do {
                try await self.meeting?.pubsub.publish(
                    topic: "ACK",
                    message: "DECLINED",
                    options: [:],
                    payload: payload
                )
            } catch {
                print("Error in declineHostChange: \(error)")
            }
        }

    }
    // Add a method to open chat
    func openChat() {
        guard let meeting = self.meeting else { return }
        let chatVC = ChatViewController(meeting: meeting, topic: "CHAT")
        let navController = UINavigationController(rootViewController: chatVC)
        UIApplication.shared.windows.first?.rootViewController?.present(
            navController,
            animated: true
        )
    }

}

// MARK: - MeetingEventListener
extension LiveStreamViewController: MeetingEventListener {
    
    func onMeetingJoined() {
        guard let localParticipant = self.meeting?.localParticipant else {
            return
        }
        self.localParticipant = localParticipant
        self.participants.append(localParticipant)
        // add event listener
        localParticipant.addEventListener(self)
        Task {
            await meeting?.pubsub.subscribe(
                topic: "REACTION",
                forListener: self
            )
            await meeting?.pubsub.subscribe(topic: "CHAT", forListener: self)
            await meeting?.pubsub.subscribe(
                topic: "HOSTREQUESTED",
                forListener: self
            )
            await meeting?.pubsub.subscribe(topic: "ACK", forListener: self)
        }
    }

    func onParticipantJoined(_ participant: Participant) {
        DispatchQueue.main.async {
            if !self.participants.contains(where: { $0.id == participant.id }) {
                self.participants.append(participant)
            }
        }
        // add listener
        participant.addEventListener(self)
    }

    func onParticipantLeft(_ participant: Participant) {
        participants = participants.filter({ $0.id != participant.id })
    }

    func onMeetingLeft() {
        meeting?.localParticipant.removeEventListener(self)
        meeting?.removeEventListener(self)
        Task {
            await meeting?.pubsub.unsubscribe(
                topic: "REACTION",
                forListener: self
            )
            await meeting?.pubsub.unsubscribe(topic: "CHAT", forListener: self)
            await meeting?.pubsub.unsubscribe(
                topic: "HOSTREQUESTED",
                forListener: self
            )
            await meeting?.pubsub.unsubscribe(topic: "ACK", forListener: self)
        }
        participants.removeAll()
    }
    
    func onMeetingStateChanged(meetingState: MeetingState) {
        switch meetingState {

        case .DISCONNECTED, .FAILED:
            print("Meeting State is \(meetingState.rawValue)")
            participants.removeAll()

        default:
            print("Meeting State is \(meetingState.rawValue)")
        }
    }

    func onParticipantModeChanged(participantId: String, mode: VideoSDKRTC.Mode)
    {
        print(
            "Participant \(self.participants.first(where: { $0.id == participantId })?.displayName ?? "") mode changed to \(mode.rawValue)"
        )
        let participant = self.participants.first { $0.id == participantId }
        if participant != nil {
            DispatchQueue.main.async {
                // Update participant in the list
                if let index = self.participants.firstIndex(where: {
                    $0.id == participant!.id
                }) {
                    self.participants[index] = participant!

                    // If switching to RECV_ONLY, remove their video tracks and status
                    if participant!.mode == .RECV_ONLY {
                        self.participantVideoTracks.removeValue(
                            forKey: participant!.id
                        )
                        self.participantCameraStatus.removeValue(
                            forKey: participant!.id
                        )
                        self.participantMicStatus.removeValue(
                            forKey: participant!.id
                        )
                    }
                }
            }
        }

    }
}

// MARK: - ParticipantEventListener
extension LiveStreamViewController: ParticipantEventListener {
    func onStreamEnabled(
        _ stream: MediaStream,
        forParticipant participant: Participant
    ) {
        // Only handle streams for SEND_AND_RECV participants
        if participant.mode == .SEND_AND_RECV {
            if let track = stream.track as? RTCVideoTrack {
                if case .state(let mediaKind) = stream.kind,
                    mediaKind == .video
                {
                    self.participantVideoTracks[participant.id] = track
                    self.participantCameraStatus[participant.id] = true
                }
            }

            if case .state(let mediaKind) = stream.kind, mediaKind == .audio {
                self.participantMicStatus[participant.id] = true
            }
        } else {
            // For RECV_ONLY participants, ensure their tracks are removed
            self.participantVideoTracks.removeValue(forKey: participant.id)
            self.participantCameraStatus[participant.id] = false
            self.participantMicStatus[participant.id] = false
        }
        isMicEnabled = participantMicStatus[localParticipant?.id ?? ""] ?? false
        isCamEnabled =
            participantCameraStatus[localParticipant?.id ?? ""] ?? false
    }

    func onStreamDisabled(
        _ stream: MediaStream,
        forParticipant participant: Participant
    ) {
        switch stream.kind {
        case .state(value: .video):
            self.participantVideoTracks.removeValue(forKey: participant.id)
            self.participantCameraStatus[participant.id] = false

        case .state(value: .audio):
            self.participantMicStatus[participant.id] = false

        default:
            print("stream kind: \(stream.kind)")
        }
        isMicEnabled = participantMicStatus[localParticipant?.id ?? ""] ?? false
        isCamEnabled =
            participantCameraStatus[localParticipant?.id ?? ""] ?? false
    }
}

// MARK: - PubSubMessageListener
extension LiveStreamViewController: PubSubMessageListener {

    func onMessageReceived(_ message: VideoSDKRTC.PubSubMessage) {
        print("Message Received:= " + message.message)

        switch message.topic {
        case "REACTION":
            DispatchQueue.main.async {
                print("Received reaction: \(message.message)")
                self.reactions.append(message.message)

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if let index = self.reactions.firstIndex(
                        of: message.message
                    ) {
                        self.reactions.remove(at: index)
                    }
                }
            }
            break

        case "CHAT":
            onPubsubMessagGetPrint.shared.pubsubMessage = message

        case "HOSTREQUESTED":
            // Check if the message sender is not the first participant (requesting participant)
            if message.senderId != participants.first?.id {
                let json = message.payload
                if !json.isEmpty {
                    if let participantId = json["receiverId"] as? String,
                        let participantName = json["senderName"] as? String
                    {
                        // Store the senderId in the requestFrom variable
                        self.requestFrom = json["senderId"] as? String

                        if participantId == participants.first?.id {
                            DispatchQueue.main.async {
                                self.showHostRequestAlert(
                                    participantId: participantId,
                                    participantName: participantName
                                )
                            }
                        }
                    }
                }
            }

        case "ACK":
            // Check the response from the other participant
            let json = message.payload
            if !json.isEmpty {
                if let toSendTo = json["receiverId"] as? String,
                    let toPrintName = json["accpeterName"] as? String
                {
                    if toSendTo == participants.first?.id {
                        if message.message == "ACCEPTED" {
                            DispatchQueue.main.async {
                                self.alertTitle = "Host Request Accepted"
                                self.alertMessage =
                                    "The request to become the host has been accepted by \(toPrintName)."
                                self.showAlert = true
                                self.showActionButtons = false
                                Task {
                                    await self.meeting?.changeMode(
                                        .SEND_AND_RECV
                                    )
                                }
                            }
                        } else if message.message == "DECLINED" {
                            DispatchQueue.main.async {
                                self.alertTitle = "Host Request Rejected"
                                self.alertMessage =
                                    "The request to become the host has been declined by \(toPrintName)."
                                self.showAlert = true
                                self.showActionButtons = false
                            }
                        }
                    }
                }
            }

        default:
            print(
                "Message Topic: \(message.topic) | message: \(message.message)"
            )
        }
    }
}
