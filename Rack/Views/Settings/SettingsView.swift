import SwiftUI

private let anthropicKeyStorageKey = "anthropic_api_key"

struct SettingsView: View {
    @AppStorage(anthropicKeyStorageKey) private var anthropicAPIKey = ""
    @State private var isKeyVisible = false

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
                    LabeledContent("Price Estimation", value: anthropicAPIKey.isEmpty ? "Disabled" : "Enabled")
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
