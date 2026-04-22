import SwiftUI
import PhotosUI
import UIKit

/// Camera capture (photo or video) wrapped for SwiftUI.
struct CameraPicker: UIViewControllerRepresentable {
    enum Mode { case photo, video }

    let mode: Mode
    let onImage: (UIImage) -> Void
    let onVideo: (URL) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = (mode == .photo) ? .photo : .video
        picker.mediaTypes = (mode == .photo) ? ["public.image"] : ["public.movie"]
        picker.videoMaximumDuration = 60
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            } else if let url = info[.mediaURL] as? URL {
                parent.onVideo(url)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
            picker.dismiss(animated: true)
        }
    }
}

/// Library picker (photo + video) using PhotosUI.
struct LibraryPicker: View {
    @Binding var selection: [PhotosPickerItem]
    let onLoaded: (UIImage?, URL?) -> Void

    var body: some View {
        PhotosPicker(
            selection: $selection,
            maxSelectionCount: 4,
            matching: .any(of: [.images, .videos])
        ) {
            Label("Photo / Video Library", systemImage: "photo.on.rectangle.angled")
        }
        .onChange(of: selection) { _, items in
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run { onLoaded(image, nil) }
                        continue
                    }
                    if let movie = try? await item.loadTransferable(type: MovieTransferable.self) {
                        await MainActor.run { onLoaded(nil, movie.url) }
                    }
                }
                await MainActor.run { selection = [] }
            }
        }
    }
}

/// Photos picker needs a Transferable to hand back a local file URL for a
/// video. We copy the movie into the app's tmp directory.
struct MovieTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(received.file.pathExtension)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.copyItem(at: received.file, to: dest)
            return MovieTransferable(url: dest)
        }
    }
}
