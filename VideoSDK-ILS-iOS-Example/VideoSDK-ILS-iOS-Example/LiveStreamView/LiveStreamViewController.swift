//
//  LiveStreamViewController.swift
//  VideoSDK-ILS-iOS-Example
//
//  Created by Deep Bhupatkar on 18/01/25.
//

import Foundation
import VideoSDKRTC
import WebRTC
import SwiftUI
import EmojiPicker

class LiveStreamViewController: ObservableObject {
    
    var token = "YOUR_TOKEN"
    var meetingId: String = ""
    var name: String = ""
    var selectedEmoji: Emoji?
    // Add this property to store the sender's ID from the host request
    var requestFrom: String?
    
    @Published var meeting: Meeting? = nil
    @Published var localParticipantView: VideoView? = nil
    @Published var participants: [Participant] = []
    @Published var streamID: String = ""
    @Published var participantVideoTracks: [String: RTCVideoTrack] = [:]
    @Published var participantMicStatus: [String: Bool] = [:]
    @Published var participantCameraStatus: [String: Bool] = [:]

    @Published var reactions: [String] = []
    
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showActionButtons = false

    func initializeStream(streamId: String, userName: String, mode: Mode) {
        // Initialize the meeting
        var videoMediaTrack = try? VideoSDK.createCameraVideoTrack(
            encoderConfig: .h720p_w1280p,
            facingMode: .front,
            multiStream: false
        )
        meeting = VideoSDK.initMeeting(
            meetingId: streamId,
            participantName: userName,
            micEnabled: true,
            webcamEnabled: true,
            customCameraVideoStream: videoMediaTrack,
            mode: mode
        )
        // Add event listeners and join the meeting
        meeting?.join()
        meeting?.addEventListener(self)

    }
    
    func sendTheReaction(_ emoji: Emoji) {
        print("Sending reaction: \(emoji.value)")
        self.meeting?.pubsub.publish(topic: "REACTION", message: emoji.value, options: [:])
    }
    
    func showHostRequestAlert(participantId: String, participantName: String) {
         self.alertTitle = "Host Request"
         self.alertMessage = "\(participantName) has requested to become the host. Do you accept?"
         self.showAlert = true
         self.showActionButtons = true
    }
    
    func sendTheHostRequest(_ participant: Participant) {
        let message = "Request for mode change your mode"
        let senderName = participants.first?.displayName ?? "Unknown"
        let senderId = participants.first?.id ?? "Unknown"
        let payload = """
               {
                   "receiverId": "\(participant.id)",
                   "senderName": "\(senderName)",
                   "senderId": "\(senderId)"
               }
               """
                print("sendTheHostRequest \(payload)")
          self.meeting?.pubsub.publish(topic: "HOSTREQUESTED", message: message, options: [:], payload: payload)
     }

     func acceptHostChange() {
        let senderName = participants.first?.displayName ?? "Unknown"
        let recvID = requestFrom ?? "Unknown"
        let payload = """
               {
                    "receiverId": "\(recvID)",
                    "accpeterName": "\(senderName)"
               } 
               """
        Task {
            await meeting?.changeMode(.SEND_AND_RECV)
        }
        self.meeting?.pubsub.publish(topic: "ACK", message: "ACCEPTED", options: [:],payload: payload)
      }
    
     func declineHostChange() {
        let senderName = participants.first?.displayName ?? "Unknown"
        let recvID = requestFrom ?? "Unknown"
        let payload = """
                {
                     "receiverId": "\(recvID)",
                     "accpeterName": "\(senderName)"
                } 
                """
        print("declineHostChange \(payload)")
        self.meeting?.pubsub.publish(topic: "ACK", message: "DECLINED", options: [:],payload: payload)
    }
    
    // Add a method to open chat
    func openChat() {
        guard let meeting = self.meeting else { return }
        let chatVC = ChatViewController(meeting: meeting, topic: "CHAT")
        let navController = UINavigationController(rootViewController: chatVC)
        UIApplication.shared.windows.first?.rootViewController?.present(navController, animated: true)
    }

}

extension LiveStreamViewController: MeetingEventListener {
    func onMeetingJoined() {
        guard let localParticipant = self.meeting?.localParticipant else { return }
 
         DispatchQueue.main.async {
            self.participants.append(localParticipant)
         }
        // add event listener
        localParticipant.addEventListener(self)
        
        localParticipant.setQuality(.high)
        
        Task {
            await meeting?.pubsub.subscribe(topic: "REACTION", forListener: self)
            await meeting?.pubsub.subscribe(topic: "CHAT", forListener: self)
            await meeting?.pubsub.subscribe(topic: "HOSTREQUESTED", forListener: self)
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
        
        participant.setQuality(.high)
    }
    
    func onParticipantLeft(_ participant: Participant) {
        participants = participants.filter({ $0.id != participant.id })
    }
    
    func onMeetingLeft() {
        meeting?.localParticipant.removeEventListener(self)
        meeting?.removeEventListener(self)
        Task{
            await meeting?.pubsub.unsubscribe(topic: "REACTION", forListener: self)
            await meeting?.pubsub.subscribe(topic: "CHAT", forListener: self)
            await meeting?.pubsub.unsubscribe(topic: "HOSTREQUESTED", forListener: self)
            await meeting?.pubsub.unsubscribe(topic: "ACK", forListener: self)
        }
        participants.removeAll()
        
    }
    func onMeetingStateChanged(meetingState: MeetingState) {
        switch meetingState {

        case .CLOSED:
            participants.removeAll()
            
        default:
            print("")
        }
    }
    func onParticipantModeChanged(_ participant: Participant) {
        DispatchQueue.main.async {
            // Update participant in the list
            if let index = self.participants.firstIndex(where: { $0.id == participant.id }) {
                self.participants[index] = participant
                
                // If switching to RECV_ONLY, remove their video tracks and status
                if participant.mode == .RECV_ONLY {
                    self.participantVideoTracks.removeValue(forKey: participant.id)
                    self.participantCameraStatus.removeValue(forKey: participant.id)
                    self.participantMicStatus.removeValue(forKey: participant.id)
                }
            }
        }
    }
}

extension LiveStreamViewController: ParticipantEventListener {
    func onStreamEnabled(_ stream: MediaStream, forParticipant participant: Participant) {
        DispatchQueue.main.async {
            // Only handle streams for SEND_AND_RECV participants
            if participant.mode == .SEND_AND_RECV {
                if let track = stream.track as? RTCVideoTrack {
                    if case .state(let mediaKind) = stream.kind, mediaKind == .video {
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
        }
    }

    func onStreamDisabled(_ stream: MediaStream, forParticipant participant: Participant) {
        DispatchQueue.main.async {
            if case .state(let mediaKind) = stream.kind {
                switch mediaKind {
                case .video:
                    self.participantVideoTracks.removeValue(forKey: participant.id)
                    self.participantCameraStatus[participant.id] = false
                case .audio:
                    self.participantMicStatus[participant.id] = false
                }
            }
        }
    }
}

// MARK: - PubSubMessageListener

extension LiveStreamViewController : PubSubMessageListener
{
    
    func onMessageReceived(_ message: VideoSDKRTC.PubSubMessage) {
        print("Message Received:= " + message.message)
        
        if message.topic == "REACTION" {
            DispatchQueue.main.async {
                print("Received reaction: \(message.message)")
                self.reactions.append(message.message)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if let index = self.reactions.firstIndex(of: message.message) {
                        self.reactions.remove(at: index)
                    }
                }
            }
        }
        else if message.topic == "CHAT" {
            onPubsubMessagGetPrint.shared.pubsubMessage = message
        }
        
        else if message.topic == "HOSTREQUESTED" {
            // Check if the message sender is not the first participant (requesting participant)
            if message.senderId != participants.first?.id {
                if let json = message.payload as? [String: Any] {
                    if let participantId = json["receiverId"] as? String,
                       let participantName = json["senderName"] as? String {
                        
                        // Store the senderId in the requestFrom variable
                        self.requestFrom = json["senderId"] as? String
                        
                        if participantId == participants.first?.id {
                            DispatchQueue.main.async {
                                self.showHostRequestAlert(participantId: participantId, participantName: participantName)
                            }
                        }
                    }
                }
            }
        }
        
        else if message.topic == "ACK" {
            // Check the response from the other participant
            if let json = message.payload as? [String: Any]
            {
                if let tosendto = json["receiverId"] as? String,
                   let toprintname = json["accpeterName"] as? String {
                    if tosendto == participants.first?.id {
                    if message.message == "ACCEPTED" {
                        DispatchQueue.main.async {
                            self.alertTitle = "Host Request Accepted"
                            self.alertMessage = "The request to become the host has been accepted by \(toprintname)."
                            self.showAlert = true
                            self.showActionButtons = false
                        }
                    } else if message.message == "DECLINED" {
                        DispatchQueue.main.async {
                            self.alertTitle = "Host Request Rejected"
                            self.alertMessage = "The request to become the host has been declined by \(toprintname)."
                            self.showAlert = true
                            self.showActionButtons = false
                        }
                    }
                }
             }
          }
       }
    }
}

extension LiveStreamViewController {
    
    func joinRoom(userName: String, mode: Mode) {
        
        let urlString = "https://api.videosdk.live/v2/rooms"
        let session = URLSession.shared
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(self.token, forHTTPHeaderField: "Authorization")
        
        session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
         
            if let data = data, let utf8Text = String(data: data, encoding: .utf8)
            {
                do{
                    let dataArray = try JSONDecoder().decode(RoomStruct.self,from: data)
                    DispatchQueue.main.async {
                        print(dataArray.roomID)
                        self.streamID = dataArray.roomID!
                        self.joinStream(streamId: dataArray.roomID!, userName: userName, mode: mode)
                    }
                    print(dataArray)
                } catch {
                    print(error)
                }
            }
        }
        ).resume()
    }
    
    func joinStream(streamId: String, userName: String, mode: Mode) {
        if !token.isEmpty {
            // use provided token for the meeting
            self.streamID = streamId
            self.initializeStream(streamId: streamId, userName: userName, mode: mode)
        }
        else {
            print("Auth token required")
            
        }
    }
}
