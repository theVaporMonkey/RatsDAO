import SwiftUI
import PhotosUI
import UIKit

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @StateObject private var speech = SpeechService()

    @State private var showingCameraPhoto = false
    @State private var showingCameraVideo = false
    @State private var showingEscalate = false
    @State private var showingEscalateConfirmation = false
    @State private var libraryItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(spacing: 0) {
            header
            messageList
            composer
        }
        .background(PoolDuckTheme.surface)
        .navigationTitle(viewModel.problem.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEscalate = true
                } label: {
                    Label("Escalate", systemImage: "tray.and.arrow.up.fill")
                }
                .tint(PoolDuckTheme.deepTeal)
            }
        }
        .task {
            _ = await speech.requestAuthorization()
        }
        .onChange(of: speech.transcript) { _, newValue in
            if speech.isRecording {
                viewModel.inputText = newValue
            }
        }
        .sheet(isPresented: $showingCameraPhoto) {
            CameraPicker(
                mode: .photo,
                onImage: { viewModel.attach(image: $0) },
                onVideo: { _ in },
                onCancel: {}
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingCameraVideo) {
            CameraPicker(
                mode: .video,
                onImage: { _ in },
                onVideo: { viewModel.attach(videoAt: $0) },
                onCancel: {}
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingEscalate) {
            EscalateView(
                viewModel: viewModel,
                onSubmitted: { _ in
                    showingEscalate = false
                    showingEscalateConfirmation = true
                },
                onCancel: { showingEscalate = false }
            )
        }
        .alert("Sent to office", isPresented: $showingEscalateConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The admin has everything they need to schedule a repair for \(viewModel.customer.name).")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.problem.systemIcon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(PoolDuckTheme.deepTeal))
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.problem.rawValue).font(.headline)
                    Text("Powered by Claude").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }

            if !viewModel.customer.name.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundStyle(PoolDuckTheme.deepTeal)
                    Text(viewModel.customer.name)
                        .font(.caption).bold()
                    Text("·").foregroundStyle(.secondary)
                    Text(viewModel.customer.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoolDuckTheme.surfaceMuted)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message).id(message.id)
                    }
                    if viewModel.isSending {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("The duck is thinking…")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 10) {
            if !viewModel.pendingAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.pendingAttachments) { att in
                            AttachmentChip(attachment: att) {
                                viewModel.removeAttachment(att)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            HStack(alignment: .bottom, spacing: 8) {
                Menu {
                    Button { showingCameraPhoto = true } label: {
                        Label("Take Photo", systemImage: "camera.fill")
                    }
                    Button { showingCameraVideo = true } label: {
                        Label("Record Video", systemImage: "video.fill")
                    }
                    LibraryPicker(selection: $libraryItems) { image, url in
                        if let image { viewModel.attach(image: image) }
                        if let url { viewModel.attach(videoAt: url) }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(PoolDuckTheme.deepTeal)
                }

                TextField("Describe the issue…", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(PoolDuckTheme.surfaceMuted)
                    )
                    .lineLimit(1...5)

                Button {
                    if speech.isRecording {
                        speech.stop()
                    } else {
                        speech.start()
                    }
                } label: {
                    Image(systemName: speech.isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 24))
                        .foregroundStyle(speech.isRecording ? .red : PoolDuckTheme.deepTeal)
                        .frame(width: 40, height: 40)
                }

                Button {
                    Task { await viewModel.send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(canSend ? PoolDuckTheme.deepTeal : .gray.opacity(0.4))
                }
                .disabled(!canSend)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(
            PoolDuckTheme.surface
                .shadow(color: .black.opacity(0.08), radius: 6, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var canSend: Bool {
        !viewModel.isSending &&
        (!viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty ||
         !viewModel.pendingAttachments.isEmpty)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .technician { Spacer(minLength: 40) }
            content
            if message.role != .technician { Spacer(minLength: 40) }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var content: some View {
        switch message.role {
        case .technician:
            VStack(alignment: .trailing, spacing: 6) {
                if !message.attachments.isEmpty { attachmentRow }
                if !message.text.isEmpty {
                    Text(message.text)
                        .padding(12)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(PoolDuckTheme.deepTeal)
                        )
                }
            }
        case .duck:
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "bubble.left.fill")
                    .foregroundStyle(PoolDuckTheme.duckGreen)
                    .padding(.top, 8)
                Text(.init(message.text))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(PoolDuckTheme.surfaceMuted)
                    )
            }
        case .system:
            Text(message.text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
        }
    }

    private var attachmentRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(message.attachments) { att in
                    if let img = UIImage(data: att.jpegData) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(alignment: .topTrailing) {
                                if att.kind == .video {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .padding(6)
                                }
                            }
                    }
                }
            }
        }
    }
}

private struct AttachmentChip: View {
    let attachment: Attachment
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let img = UIImage(data: attachment.jpegData) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white, .black.opacity(0.65))
                    .font(.title3)
            }
            .padding(2)
            if attachment.kind == .video {
                Image(systemName: "video.fill")
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Color.black.opacity(0.5), in: Circle())
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .frame(width: 72, height: 72)
    }
}
