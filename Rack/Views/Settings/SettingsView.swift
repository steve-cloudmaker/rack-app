import SwiftUI
import CoreData

private let anthropicKeyStorageKey = "anthropic_api_key"

struct SettingsView: View {
    @AppStorage(anthropicKeyStorageKey) private var anthropicAPIKey = ""
    @State private var isKeyVisible   = false
    @State private var shareConfig: ShareConfig?
    @State private var sharingError: String?
    @State private var isPreparingShare = false

    @FetchRequest(fetchRequest: {
        let req = ClothingItem.fetchRequest()
        req.fetchLimit = 1
        req.sortDescriptors = [NSSortDescriptor(keyPath: \ClothingItem.createdAt, ascending: true)]
        return req
    }()) private var firstItem: FetchedResults<ClothingItem>

    private var hasItems: Bool { !firstItem.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        if isKeyVisible {
                            TextField("sk-ant-...", text: $anthropicAPIKey)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("sk-ant-...", text: $anthropicAPIKey)
                        }
                        Button {
                            isKeyVisible.toggle()
                        } label: {
                            Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                } header: {
                    Text("Anthropic API Key")
                } footer: {
                    Text("Used for AI-powered description generation and price estimation. Your key is stored only on this device.")
                }

                Section("AI Features") {
                    LabeledContent("Description Generation", value: anthropicAPIKey.isEmpty ? "Disabled" : "Enabled")
                    LabeledContent("Price Estimation",       value: anthropicAPIKey.isEmpty ? "Disabled" : "Enabled")
                }

                Section {
                    if hasItems {
                        Button {
                            isPreparingShare = true
                            Task {
                                do {
                                    shareConfig = try await PersistenceController.shared.prepareShare()
                                } catch {
                                    sharingError = error.localizedDescription
                                }
                                isPreparingShare = false
                            }
                        } label: {
                            HStack {
                                Label("Share Closet…", systemImage: "person.2.badge.plus")
                                Spacer()
                                if isPreparingShare { ProgressView().scaleEffect(0.8) }
                            }
                        }
                        .disabled(isPreparingShare)
                    } else {
                        Label("Add items to enable sharing.", systemImage: "person.2.badge.plus")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Family Sharing")
                } footer: {
                    Text("Share your entire closet with family members. Anyone you invite can view and edit all items.")
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
            .scrollContentBackground(.hidden)
            .background(TartanView().ignoresSafeArea().opacity(0.20))
            .navigationTitle("Settings")
            .sheet(item: $shareConfig) { config in
                CloudSharingView(share: config.share, container: config.container) {
                    shareConfig = nil
                }
            }
            .alert("Sharing Error", isPresented: .constant(sharingError != nil)) {
                Button("OK") { sharingError = nil }
            } message: {
                Text(sharingError ?? "")
            }
        }
    }
}
