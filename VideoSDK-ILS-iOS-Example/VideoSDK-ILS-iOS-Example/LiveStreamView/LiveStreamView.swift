//
//  LiveStreamView.swift
//  VideoSDK-ILS-iOS-Example
//
//  Created by Deep Bhupatkar on 18/01/25.
//

import EmojiPicker
import SwiftUI
import VideoSDKRTC
import WebRTC

struct Reaction: Equatable, Identifiable {
    let id: UUID
    let emoji: String
    let startX: CGFloat
    let horizontalOffset: CGFloat
}

struct ParticipantContainerView: View {
    let participant: Participant
    @StateObject private var cameraPreview = CameraPreviewModel()
    @ObservedObject var controller: LiveStreamViewController

    // Extract subviews for better organization
    private var nameAndMicOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Text(participant.displayName)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(4)

                Image(
                    systemName: controller.participantMicStatus[
                        participant.id
                    ] ?? false ? "mic.fill" : "mic.slash.fill"
                )
                .foregroundColor(
                    controller.participantMicStatus[
                        participant.id
                    ] ?? false ? .green : .red
                )
                .padding(4)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())

                Spacer()
            }
            .padding(8)
        }
    }

    var body: some View {
        // Only render if participant is in SEND_AND_RECV mode
        if participant.mode == .SEND_AND_RECV {
            ZStack {
                participantView(
                    participant: participant,
                    controller: controller
                )
                nameAndMicOverlay
            }
            .background(Color.black.opacity(0.9))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.7), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.9), lineWidth: 1)
            )
        }
    }

    private func participantView(
        participant: Participant,
        controller: LiveStreamViewController
    ) -> some View {
        ZStack {
            ParticipantView(
                participant: participant,
                liveStreamViewController: controller
            )
        }
    }
}

struct LiveStreamView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var controller: LiveStreamViewController

    @State var streamId: String?
    @State var userName: String?

    // for actionsheet shisMicEnabledowing and changing selected device
    @State private var showActionSheet = false
    @State private var selectedAudioDevice: String?
    @State private var audioDeviceList: [String] = []
    @State private var selectedCameraMode: AVCaptureDevice.Position = .front
    @State private var isCameraEnabled: Bool = true
    @State private var showOptionSelector = false

    // for paricipant list
    @State private var showParticipantsList = false

    // for pubsub emojis
    @State var selectedEmoji: Emoji?
    @State var displayEmojiPicker: Bool = false

    // Add reaction-related state
    @State private var visibleReactions: [Reaction] = []
    private let maxVisibleReactions = 13
    private let copiesPerReaction = 8  // Number of copies for each reaction

    init(streamId: String? = nil, userName: String? = nil, mode: Mode) {
        self.streamId = streamId
        self.userName = userName
        self._controller = StateObject(
            wrappedValue: LiveStreamViewController(
                streamID: streamId ?? "",
                nameOfParticipant: userName ?? "Parth",
                mode: mode
            )
        )
    }

    private var isAudienceMode: Bool {
        // Derive audience mode from the current participant's mode
        if let localParticipant = controller.participants.first(
            where: { $0.isLocal })
        {
            return localParticipant.mode == .RECV_ONLY
        }
        return controller.meetingMode == .RECV_ONLY
    }

    // Add a function to generate random offset
    private func randomOffset() -> (CGFloat, CGFloat) {
        let horizontalOffset = CGFloat.random(in: -150...150)
        let startX = CGFloat.random(in: -50...50)
        return (horizontalOffset, startX)
    }

    private var reactionOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(visibleReactions) { reaction in
                    Text(reaction.emoji)
                        .font(.system(size: 40))
                        .position(
                            x: geometry.size.width / 2 + reaction.startX,
                            y: geometry.size.height - 100
                        )
                        .modifier(
                            FloatingAnimation(
                                finalY: -geometry.size.height + 100,
                                horizontalOffset: reaction.horizontalOffset
                            )
                        )
                }
            }
        }
    }

    private func getVisibleParticipants() -> [Participant] {
        // Only show participants who are in SEND_AND_RECV mode
        return controller.participants.filter { participant in
            participant.mode == .SEND_AND_RECV
        }
    }

    // Function to get total participant count (including RECV_ONLY)
    private func getTotalParticipantCount() -> Int {
        return controller.participants.count
    }

    // Function to render single participant
    private func singleParticipantView(geometry: GeometryProxy) -> some View {
        let participants = getVisibleParticipants()
        return ParticipantContainerView(
            participant: participants[0],
            controller: controller
        )
        .frame(width: geometry.size.width, height: geometry.size.height)
    }

    // Function to render two participants
    private func twoParticipantsView(geometry: GeometryProxy) -> some View {
        let participants = getVisibleParticipants()
        return VStack(spacing: 0) {
            ParticipantContainerView(
                participant: participants[0],
                controller: controller
            )
            .frame(width: geometry.size.width, height: geometry.size.height / 2)

            ParticipantContainerView(
                participant: participants[1],
                controller: controller
            )
            .frame(width: geometry.size.width, height: geometry.size.height / 2)
        }
    }

    // Function to render three participants
    private func threeParticipantsView(geometry: GeometryProxy) -> some View {
        let participants = getVisibleParticipants()
        return VStack(spacing: 0) {
            ParticipantContainerView(
                participant: participants[0],
                controller: controller
            )
            .frame(width: geometry.size.width, height: geometry.size.height / 2)

            HStack(spacing: 0) {
                ParticipantContainerView(
                    participant: participants[1],
                    controller: controller
                )
                .frame(
                    width: geometry.size.width / 2,
                    height: geometry.size.height / 2
                )

                ParticipantContainerView(
                    participant: participants[2],
                    controller: controller
                )
                .frame(
                    width: geometry.size.width / 2,
                    height: geometry.size.height / 2
                )
            }
        }
    }

    // Function to render four participants
    private func fourParticipantsView(geometry: GeometryProxy) -> some View {
        let participants = getVisibleParticipants()
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ParticipantContainerView(
                    participant: participants[0],
                    controller: controller
                )
                .frame(
                    width: geometry.size.width / 2,
                    height: geometry.size.height / 2
                )

                ParticipantContainerView(
                    participant: participants[1],
                    controller: controller
                )
                .frame(
                    width: geometry.size.width / 2,
                    height: geometry.size.height / 2
                )
            }

            HStack(spacing: 0) {
                ParticipantContainerView(
                    participant: participants[2],
                    controller: controller
                )
                .frame(
                    width: geometry.size.width / 2,
                    height: geometry.size.height / 2
                )

                ParticipantContainerView(
                    participant: participants[3],
                    controller: controller
                )
                .frame(
                    width: geometry.size.width / 2,
                    height: geometry.size.height / 2
                )
            }
        }
    }

    // Function to render more than four participants
    private func manyParticipantsView(geometry: GeometryProxy) -> some View {
        let participants = getVisibleParticipants()

        if participants.isEmpty {
            return AnyView(
                VStack {
                    Spacer()
                    Text("Waiting for participants to start streaming...")
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
            )
        } else {
            return AnyView(
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()), GridItem(.flexible()),
                        ],
                        spacing: 0
                    ) {
                        ForEach(participants, id: \.id) { participant in
                            ParticipantContainerView(
                                participant: participant,
                                controller: controller
                            )
                            .frame(height: geometry.size.height / 3)
                        }
                    }
                }
            )
        }
    }

    var body: some View {
        VStack {
            if controller.participants.count == 0 {
                Text("Joining the live stream")
            } else {
                ZStack {

                    VStack {
                        HStack {
                            // LIVE label on the left
                            if controller.participants.first?.mode
                                == .SEND_AND_RECV
                            {
                                Text("LIVE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.red)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 8)
                                    )
                            }

                            Spacer()  // Pushes the participant count to the right

                            // Participant count with person icon on the right
                            HStack(spacing: 6) {
                                Image(systemName: "person.fill")
                                    .font(.body)
                                    .foregroundColor(.white)
                                Text(
                                    "\(controller.viewerParticipantCount)"
                                )
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture {
                                showParticipantsList = !isAudienceMode
                            }
                        }

                        GeometryReader { geometry in
                            VStack(spacing: 0) {
                                let visibleParticipants =
                                    getVisibleParticipants()
                                let totalVisibleParticipants =
                                    visibleParticipants.count

                                if totalVisibleParticipants > 0 {
                                    switch totalVisibleParticipants {
                                    case 1:
                                        singleParticipantView(
                                            geometry: geometry
                                        )
                                    case 2:
                                        twoParticipantsView(geometry: geometry)
                                    case 3:
                                        threeParticipantsView(
                                            geometry: geometry
                                        )
                                    case 4:
                                        fourParticipantsView(geometry: geometry)
                                    default:
                                        manyParticipantsView(geometry: geometry)
                                    }
                                } else {
                                    // Show a message when no SEND_AND_RECV participants are available
                                    VStack {
                                        Spacer()
                                        Text(
                                            "Waiting for participants to start streaming..."
                                        )
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                        Spacer()
                                    }
                                    .frame(
                                        maxWidth: .infinity,
                                        maxHeight: .infinity
                                    )
                                    .background(Color.black.opacity(0.8))
                                }
                            }
                        }
                    }

                    GeometryReader { geometry in
                        HStack {
                            Spacer()
                            VStack(spacing: 20) {
                                Spacer()

                                // Control buttons for participants
                                if !isAudienceMode {
                                    VStack(spacing: 20) {
                                        Button {
                                            controller.isMicEnabled
                                                ? controller
                                                    .meeting?.muteMic()
                                                : controller
                                                    .meeting?.unmuteMic()
                                        } label: {
                                            Image(
                                                systemName: controller
                                                    .isMicEnabled
                                                    ? "mic.fill"
                                                    : "mic.slash.fill"
                                            )
                                            .font(.system(size: 20))
                                            .frame(width: 45, height: 45)
                                            .background(
                                                Color.white.opacity(0.3)
                                            )
                                            .clipShape(
                                                RoundedRectangle(
                                                    cornerRadius: 10
                                                )
                                            )
                                            .foregroundColor(
                                                controller.isMicEnabled
                                                    ? .white : .red
                                            )
                                        }

                                        Button {
                                            controller.isCamEnabled
                                                ? controller
                                                    .meeting?.disableWebcam()
                                                : controller
                                                    .meeting?.enableWebcam()
                                        } label: {
                                            Image(
                                                systemName: controller
                                                    .isCamEnabled
                                                    ? "video.fill"
                                                    : "video.slash.fill"
                                            )
                                            .font(.system(size: 20))
                                            .frame(width: 45, height: 45)
                                            .background(
                                                Color.white.opacity(0.3)
                                            )
                                            .clipShape(
                                                RoundedRectangle(
                                                    cornerRadius: 10
                                                )
                                            )
                                            .foregroundColor(
                                                controller.isCamEnabled
                                                    ? .white : .red
                                            )
                                        }

                                        Button {
                                            showOptionSelector = true
                                        } label: {
                                            Image(systemName: "ellipsis")
                                                .font(.system(size: 20))
                                                .frame(width: 45, height: 45)
                                                .background(
                                                    Color.white.opacity(0.3)
                                                )
                                                .clipShape(
                                                    RoundedRectangle(
                                                        cornerRadius: 10
                                                    )
                                                )
                                                .foregroundColor(.white)
                                        }
                                        .confirmationDialog(
                                            "Select an Option",
                                            isPresented: $showOptionSelector
                                        ) {
                                            Button("Select Audio Device") {
                                                fetchAudioDevices()
                                                showActionSheet = true
                                            }
                                            if isCameraEnabled {
                                                Button("Flip Camera") {
                                                    toggleCamera()
                                                }
                                            }
                                            Button("Show Participants List") {
                                                showParticipantsList = true
                                            }
                                            Button("Cancel", role: .cancel) {}
                                        }
                                        .actionSheet(
                                            isPresented: $showActionSheet
                                        ) {
                                            ActionSheet(
                                                title: Text(
                                                    "Switch Audio Device"
                                                ),
                                                buttons: buildDeviceButtons()
                                            )
                                        }
                                    }
                                }

                                // Emoji button for audience mode
                                if isAudienceMode {
                                    Button {
                                        displayEmojiPicker = true
                                    } label: {
                                        Image(systemName: "face.smiling")
                                            .font(.system(size: 20))
                                            .frame(width: 45, height: 45)
                                            .background(
                                                Color.white.opacity(0.3)
                                            )
                                            .clipShape(
                                                RoundedRectangle(
                                                    cornerRadius: 10
                                                )
                                            )
                                            .foregroundColor(.white)
                                    }
                                    .sheet(isPresented: $displayEmojiPicker) {
                                        NavigationView {
                                            EmojiPickerView(
                                                selectedEmoji: $selectedEmoji,
                                                selectedColor: .orange
                                            )
                                            .navigationTitle("Select Reaction")
                                            .navigationBarTitleDisplayMode(
                                                .inline
                                            )
                                            .navigationBarItems(
                                                trailing: Button("Send") {
                                                    if let emoji = selectedEmoji
                                                    {
                                                        controller
                                                            .sendTheReaction(
                                                                emoji
                                                            )
                                                    }
                                                    displayEmojiPicker = false
                                                }
                                            )
                                        }
                                    }
                                }

                                // Switch mode button
                                Button {
                                    let newMode: Mode =
                                        isAudienceMode
                                        ? .SEND_AND_RECV : .RECV_ONLY
                                    print("Starting mode change to \(newMode)")
                                    Task {
                                        await controller.meeting?
                                            .changeMode(newMode)
                                        controller.meetingMode = newMode
                                    }
                                } label: {
                                    Image(
                                        systemName: isAudienceMode
                                            ? "person.fill" : "person.2.fill"
                                    )
                                    .font(.system(size: 20))
                                    .frame(width: 45, height: 45)
                                    .background(Color.white.opacity(0.3))
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 10)
                                    )
                                    .foregroundColor(.white)
                                }

                                // Chat button
                                Button {
                                    controller.openChat()
                                } label: {
                                    Image(systemName: "message.circle.fill")
                                        .font(.system(size: 20))
                                        .frame(width: 45, height: 45)
                                        .background(Color.white.opacity(0.3))
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 10)
                                        )
                                        .foregroundColor(.white)
                                }

                                // Leave button
                                Button {
                                    controller.meeting?.leave()
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Image(systemName: "phone.down.fill")
                                        .font(.system(size: 20))
                                        .frame(width: 45, height: 45)
                                        .background(Color.red)
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 10)
                                        )
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 40)
                        }
                    }

                    // Add reaction overlay at the screen level
                    reactionOverlay
                }
            }
        }
        // First alert - Host Request (with Accept/Decline buttons)
        .alert(isPresented: $controller.showAlert) {
            if controller.showActionButtons {
                return Alert(
                    title: Text(controller.alertTitle),
                    message: Text(controller.alertMessage),
                    primaryButton: .default(Text("Accept")) {
                        // Handle Accept action
                        self.controller.acceptHostChange()
                    },
                    secondaryButton: .default(Text("Decline")) {
                        // Handle Decline action
                        self.controller.declineHostChange()
                    }
                )
            } else {
                return Alert(
                    title: Text(controller.alertTitle),
                    message: Text(controller.alertMessage),
                    dismissButton: .default(Text("Okay")) {
                        // Acknowledge and close the alert
                        self.controller.showAlert = false
                    }
                )
            }
        }
        .sheet(isPresented: $showParticipantsList) {
            ParticipantListView(
                participants: controller.participants,
                participantCameraStatus: controller
                    .participantCameraStatus,
                participantMicStatus: controller
                    .participantMicStatus,
                onClose: { showParticipantsList = false },
                sendHostRequest: controller.sendTheHostRequest
            )
        }
        .onChange(
            of: controller.reactions,
            { oldValue, newValue in
                if let latestReaction = newValue.last {
                    addReaction(latestReaction)
                }
            }
        )
    }
    private func fetchAudioDevices() {
        audioDeviceList = VideoSDK.getAudioDevices()
    }

    private func buildDeviceButtons() -> [ActionSheet.Button] {
        var buttons = audioDeviceList.map { device in
            ActionSheet.Button.default(
                Text("\(device)\(selectedAudioDevice == device ? " ✓" : "")")
            ) {
                selectedAudioDevice = device
                controller.meeting?.changeMic(
                    selectedDevice: device
                )
            }
        }
        buttons.append(.cancel(Text("Cancel")))
        return buttons
    }

    private func toggleCamera() {
        selectedCameraMode = (selectedCameraMode == .front) ? .back : .front
        controller.meeting?.switchWebcam()
    }

    private func addReaction(_ emoji: String) {
        // Create multiple copies of the same reaction with different paths
        for _ in 0..<copiesPerReaction {
            let (horizontalOffset, startX) = randomOffset()
            let newReaction = Reaction(
                id: UUID(),
                emoji: emoji,
                startX: startX,
                horizontalOffset: horizontalOffset
            )

            withAnimation {
                visibleReactions.append(newReaction)

                // Remove this specific reaction after animation
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + Double.random(in: 2.5...3.5)
                ) {
                    withAnimation {
                        visibleReactions.removeAll { $0.id == newReaction.id }
                    }
                }
            }
        }

        // Limit total visible reactions
        if visibleReactions.count > maxVisibleReactions {
            visibleReactions.removeFirst(
                visibleReactions.count - maxVisibleReactions
            )
        }
    }
}

struct ParticipantListView: View {
    let participants: [Participant]
    let participantCameraStatus: [String: Bool]
    let participantMicStatus: [String: Bool]
    let onClose: () -> Void
    let sendHostRequest: (Participant) -> Void

    @State private var requestedParticipantId: String?  // Track the requested participant's ID

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Participants (\(participants.count))")
                    .font(.headline)
                Spacer()
                Button("Close") {
                    onClose()
                }
                .foregroundColor(.blue)
            }
            .padding()

            List {
                ForEach(participants.indices, id: \.self) { index in
                    HStack {
                        // Index
                        Text("\(index + 1)")
                            .frame(width: 30, alignment: .leading)

                        // Participant name
                        Text(participants[index].displayName)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Show "HOST" or "Requested" tag
                        if participants[index].id == requestedParticipantId {
                            Text("Requested")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        } else if participants[index].mode == .SEND_AND_RECV {
                            Text("Host")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        if participants[index].isLocal != true {
                            // Camera status
                            Image(
                                systemName: participantCameraStatus[
                                    participants[index].id
                                ] ?? false ? "video.fill" : "video.slash.fill"
                            )
                            .foregroundColor(
                                participantCameraStatus[participants[index].id]
                                    ?? false ? .green : .red
                            )

                            // Mic status
                            Image(
                                systemName: participantMicStatus[
                                    participants[index].id
                                ] ?? false ? "mic.fill" : "mic.slash.fill"
                            )
                            .foregroundColor(
                                participantMicStatus[participants[index].id]
                                    ?? false ? .green : .red
                            )
                            .frame(width: 30)

                            // Option button to show options
                            Menu {
                                Button("Request to join as co-host") {
                                    requestedParticipantId =
                                        participants[index].id
                                    sendHostRequest(participants[index])
                                    onClose()
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    .padding(.vertical, 5)
                }
            }
        }
    }
}

/// VideoView for participant's video
class VideoView: UIView {
    var videoView: RTCMTLVideoView = {
        let view = RTCMTLVideoView()
        view.videoContentMode = .scaleAspectFill
        view.backgroundColor = UIColor.black
        view.clipsToBounds = true
        view.transform = CGAffineTransform(scaleX: 1, y: 1)

        return view
    }()

    init(track: RTCVideoTrack?, frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        // Set videoView frame to match parent view
        videoView.frame = bounds

        DispatchQueue.main.async {
            self.addSubview(self.videoView)
            self.bringSubviewToFront(self.videoView)
            track?.add(self.videoView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update videoView frame when parent view size changes
        videoView.frame = bounds
    }
}

/// ParticipantView for showing and hiding VideoView
struct ParticipantView: View {
    let participant: Participant
    @ObservedObject var liveStreamViewController: LiveStreamViewController

    var body: some View {
        ZStack {
            if participant.mode == .SEND_AND_RECV,
                let track = liveStreamViewController.participantVideoTracks[
                    participant.id
                ]
            {
                VideoStreamView(track: track)
            } else {
                Color.black.opacity(1.0)
                VStack {
                    if participant.mode == .RECV_ONLY {
                        Text("Viewer")
                            .foregroundColor(.white)
                        Text(participant.displayName)
                            .foregroundColor(.gray)
                            .font(.caption)
                    } else {
                        Text("No media")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct VideoStreamView: UIViewRepresentable {
    let track: RTCVideoTrack

    func makeUIView(context: Context) -> VideoView {
        let view = VideoView(track: track, frame: .zero)
        return view
    }

    func updateUIView(_ uiView: VideoView, context: Context) {
        track.add(uiView.videoView)
    }
}

// Add a custom animation modifier
struct FloatingAnimation: ViewModifier {
    let finalY: CGFloat
    let horizontalOffset: CGFloat

    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 0.5
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(x: xOffset, y: yOffset)
            .onAppear {
                // Random initial delay for more natural movement
                let delay = Double.random(in: 0...0.3)

                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    // Initial pop-in animation
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7))
                    {
                        scale = CGFloat.random(in: 0.8...1.2)  // Random size variation
                    }

                    // Random horizontal movement
                    withAnimation(
                        .easeInOut(duration: Double.random(in: 2.5...3.5))
                    ) {
                        xOffset = horizontalOffset
                    }

                    // Float up and fade out
                    withAnimation(
                        .easeInOut(duration: Double.random(in: 2.5...3.5))
                    ) {
                        yOffset = finalY
                        opacity = 0
                    }
                }
            }
    }
}
