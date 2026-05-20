import SwiftUI
import CoreData
import UniformTypeIdentifiers

private let anthropicKeyStorageKey = "anthropic_api_key"

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var managedObjectContext

    @AppStorage(anthropicKeyStorageKey) private var anthropicAPIKey = ""
    @State private var isKeyVisible   = false
    @State private var shareConfig: ShareConfig?
    @State private var sharingError: String?
    @State private var isPreparingShare = false
    @State private var showingCSVImporter = false
    @State private var isImporting = false
    @State private var importSuccessCount: Int?
    @State private var importError: String?

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
                    LabeledContent("Status", value: accountStatusLabel)
                    LabeledContent("Activity", value: CloudKitSyncMonitor.shared.lastEventMessage)
                    if CloudKitSyncMonitor.shared.isSyncing {
                        HStack {
                            ProgressView()
                            Text("Syncing with iCloud…")
                        }
                    }
                    Button("Refresh iCloud Status") {
                        Task { await CloudKitSyncMonitor.shared.refreshAccountStatus() }
                    }
                } header: {
                    Text("iCloud Sync")
                } footer: {
                    Text(CloudKitSyncMonitor.shared.accountStatusMessage)
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

                Section {
                    Button {
                        showingCSVImporter = true
                    } label: {
                        HStack {
                            Label("Import from CSV…", systemImage: "square.and.arrow.down")
                            Spacer()
                            if isImporting { ProgressView().scaleEffect(0.8) }
                        }
                    }
                    .disabled(isImporting)
                } header: {
                    Text("Data")
                } footer: {
                    Text("Import clothing items from a CSV file. Expected columns include description, brand, color, size, type, status, owner, and location.")
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
            .scrollContentBackground(.hidden)
            .background(TartanView().ignoresSafeArea().opacity(0.20))
            .navigationTitle("Settings")
            .task {
                await CloudKitSyncMonitor.shared.refreshAccountStatus()
            }
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
            .alert("Import Complete", isPresented: .constant(importSuccessCount != nil)) {
                Button("OK") { importSuccessCount = nil }
            } message: {
                Text("Imported \(importSuccessCount ?? 0) item\(importSuccessCount == 1 ? "" : "s").")
            }
            .alert("Import Failed", isPresented: .constant(importError != nil)) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
            .fileImporter(
                isPresented: $showingCSVImporter,
                allowedContentTypes: [.commaSeparatedText, .plainText, .text],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importCSV(from: url)
                case .failure(let error):
                    importError = error.localizedDescription
                }
            }
        }
    }

    private var accountStatusLabel: String {
        switch CloudKitSyncMonitor.shared.accountStatus {
        case .available: return "Available"
        case .noAccount: return "Not Signed In"
        case .restricted: return "Restricted"
        case .temporarilyUnavailable: return "Unavailable"
        case .couldNotDetermine: return "Unknown"
        @unknown default: return "Unknown"
        }
    }

    private func importCSV(from url: URL) {
        isImporting = true
        Task { @MainActor in
            defer { isImporting = false }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            do {
                let count = try CSVImporter.import(from: url, context: managedObjectContext)
                importSuccessCount = count
            } catch {
                importError = error.localizedDescription
            }
        }
    }
}
