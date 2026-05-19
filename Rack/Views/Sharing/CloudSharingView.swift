import SwiftUI
import CloudKit

struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    var didFinish: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowPublic, .allowPrivate, .allowReadWrite, .allowReadOnly]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let parent: CloudSharingView
        init(_ parent: CloudSharingView) { self.parent = parent }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            parent.didFinish()
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            parent.didFinish()
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("[Cedar] CloudSharing error: \(error)")
            parent.didFinish()
        }

        func itemTitle(for csc: UICloudSharingController) -> String? { "Cedar Closet" }
    }
}
