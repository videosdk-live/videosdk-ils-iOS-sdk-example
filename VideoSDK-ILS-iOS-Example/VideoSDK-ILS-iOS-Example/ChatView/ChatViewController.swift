//
//  ChatViewController.swift
//  VideoSDK-ILS-iOS-Example
//
//  Created by Deep Bhupatkar on 18/01/25.
//


import UIKit
import MessageKit
import InputBarAccessoryView
import VideoSDKRTC

struct Sender: SenderType {
    var senderId: String  // Unique identifier for the sender
    var displayName: String
}

class ChatViewController: MessagesViewController {

    private let currentUser = Sender(senderId: "self", displayName: "Me") // Using senderId as the identifier

    
    // MARK: - Properties
    
    /// Meeting Reference
    public var meeting: Meeting
    
    /// Chat Topic
    public var topic: String
    
    /// Message List
    private var messages: [Message] = []
    
    // Time Formatter
    private let timeFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private var metaData: [String: Any]?
    
    // MARK: - Init
    
    init(meeting: Meeting, topic: String,metaData: [String: Any]? = nil) {
        self.meeting = meeting
        self.topic = topic
        self.metaData = metaData
        
        let pubsubMessages = meeting.pubsub.getMessagesForTopic(topic)
        messages = pubsubMessages.map({ Message(pubsubMessage: $0) })
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMessagesCollectionView()
        setupInputBar()
        onPubSubMessageReceived()
    }
    
    
    private func setupMessagesCollectionView() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        // Adjust content inset to account for header view
        messagesCollectionView.contentInset = UIEdgeInsets(top: 45, left: 0, bottom: 0, right: 0)
        messagesCollectionView.scrollIndicatorInsets = UIEdgeInsets(top: 45, left: 0, bottom: 0, right: 0)
        
        // Customize the message bubbles
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
        }
    }
    
    private func setupInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.placeholder = "Type a message"
        messageInputBar.sendButton.setTitle("Send", for: .normal)
    }

}

// Add this to maintain proper layout
extension ChatViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

// MARK: - MessagesDataSource
extension ChatViewController: MessagesDataSource {
    var currentSender: any MessageKit.SenderType {
        return ChatUser(senderId: meeting.localParticipant.id, displayName: meeting.localParticipant.displayName)
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}

// MARK: - MessagesLayoutDelegate & MessagesDisplayDelegate
extension ChatViewController: MessagesLayoutDelegate, MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .systemBlue : .systemGray5
    }
}

// MARK: - InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // Create and add the user message directly
        if let pubsubMessage = onPubsubMessagGetPrint.shared.pubsubMessage {
            // Create the Message object using the stored PubSubMessage
            let message = Message(pubsubMessage: pubsubMessage)
            
            // Only append the message to the messages array if it's not from the current user
            if message.sender.senderId != currentUser.senderId {
                messages.append(message)
            }
        }

        // Publish the message to the PubSub topic
        Task {
            // Send the message using PubSub without needing to pass pubsubMessage
            meeting.pubsub.publish(topic: topic, message: text, options: ["persist": true])
        }

        // Print the message for debugging
        print("Sent message: \(text)")

        // Clear the input bar and reload the collection view
        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
    }

    func onPubSubMessageReceived() {
        // Observe updates from onPubsubMessagGetPrint
        onPubsubMessagGetPrint.shared.messageUpdated = { [weak self] pubsubMessage in
            guard let self = self, let pubsubMessage = pubsubMessage else { return }
            
            // Create a message from the received response
            let message = Message(pubsubMessage: pubsubMessage) // Ensure to use the correct type

           
            // Only append the received message to the messages array if it's not from the current user
            if message.sender.senderId != self.currentUser.senderId {
                self.messages.append(message)
            }
            
            if messages.isEmpty != false {
                self.messages.removeLast()
            }

            // Print the message (or perform any necessary actions)
            print(pubsubMessage.message)  // You can log the message here

            // Reload the collection view and scroll to the last item
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToLastItem(animated: true)
        }
    }
}


class onPubsubMessagGetPrint {
    static let shared = onPubsubMessagGetPrint()
    
    @Published var pubsubMessage: PubSubMessage? {
        didSet {
            messageUpdated?(pubsubMessage)
        }
    }
    
    var messageUpdated: ((PubSubMessage?) -> Void)?
    
    private init() {}
}
