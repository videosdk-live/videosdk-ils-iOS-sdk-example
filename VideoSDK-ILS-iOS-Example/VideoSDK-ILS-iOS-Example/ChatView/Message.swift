//
//  Message.swift
//  VideoSDK-ILS-iOS-Example
//
//  Created by Deep Bhupatkar on 18/01/25.
//


import Foundation
import MessageKit
import VideoSDKRTC

struct Message: MessageType {
    
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    // MARK: - Init
    
    init(pubsubMessage: PubSubMessage) {
        messageId = pubsubMessage.id
        kind = .text(pubsubMessage.message)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        sentDate = dateFormatter.date(from: pubsubMessage.timestamp) ?? Date()
        sender = ChatUser(senderId: pubsubMessage.senderId, displayName: pubsubMessage.senderName)
    }
}


