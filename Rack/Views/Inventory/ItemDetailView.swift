import SwiftUI
import CoreData
import PhotosUI

struct ItemDetailView: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Person.name, ascending: true)]
    ) private var people: FetchedResults<Person>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StorageLocation.name, ascending: true)]
    ) private var locations: FetchedResults<StorageLocation>

    private let existingItem: ClothingItem?
    @State private var draft = ItemDraft()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var isGeneratingDescription = false
    @State private var isEstimatingPrice = false
    @State private var showingAddLocation = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false

    @AppStorage("anthropic_api_key") private var anthropicAPIKey = ""
    private var aiEnabled: Bool { !anthropicAPIKey.isEmpty }

    init(item: ClothingItem?) {
        self.existingItem = item
        if let item {
            _draft     = State(initialValue: ItemDraft(from: item))
            _photoData = State(initialValue: item.sortedPhotos.compactMap { $0.imageData })
        }
    }

    var isNew: Bool { existingItem == nil }

    var body: some View {
        NavigationStack {
            Form {
                photosSection
                coreDetailsSection
                classificationSection
                statusSection
                locationSection
            }
            .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotos, maxSelectionCount: 5 - photoData.count, matching: .images)
            .sheet(isPresented: $showingCamera) {
                CameraView { data in photoData.append(data) }
            }
            .navigationTitle(isNew ? "New Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(draft.itemDescription.isEmpty && draft.brand.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddLocation) {
                AddLocationView { newID in draft.locationID = newID }
            }
        }
    }

    // MARK: - Sections

    private var photosSection: some View {
        Section("Photos") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(photoData.indices, id: \.self) { index in
                        if let image = UIImage(data: photoData[index]) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                Button {
                                    photoData.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, .black.opacity(0.6))
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                    if photoData.count < 5 {
                        Menu {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button { showingCamera = true } label: {
                                    Label("Take Photo", systemImage: "camera")
                                }
                            }
                            Button { showingPhotoPicker = true } label: {
                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(width: 100, height: 100)
                                .overlay(Image(systemName: "plus").font(.title2).foregroundStyle(.secondary))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
        .onChange(of: selectedPhotos) { _, newItems in loadPhotos(from: newItems) }
    }

    private var coreDetailsSection: some View {
        Section("Details") {
            HStack {
                TextField("Description", text: $draft.itemDescription)
                if isGeneratingDescription {
                    ProgressView().scaleEffect(0.8)
                } else if aiEnabled && !photoData.isEmpty {
                    Button { Task { await generateDescription() } } label: {
                        Image(systemName: "wand.and.stars").foregroundStyle(.purple)
                    }
                    .buttonStyle(.borderless)
                }
            }
            TextField("Brand", text: $draft.brand)
            TextField("Color", text: $draft.color)
            Picker("Condition", selection: $draft.condition) {
                ForEach(ItemCondition.allCases) { c in Text(c.displayName).tag(c) }
            }
        }
    }

    private var classificationSection: some View {
        Section("Classification") {
            Picker("Age Group", selection: $draft.ageGroup) {
                ForEach(AgeGroup.allCases) { g in Text(g.displayName).tag(g) }
            }
            .onChange(of: draft.ageGroup) { _, newGroup in
                if draft.clothingType.isKidsOnly && newGroup == .adult {
                    draft.clothingType = .shirts
                }
                if let size = draft.size, !ClothingSize.available(for: newGroup).contains(size) {
                    draft.size = nil
                }
                if let shoeSize = draft.shoeSize, !ShoeSize.available(for: newGroup).contains(shoeSize) {
                    draft.shoeSize = nil
                }
            }

            Picker("Gender", selection: $draft.gender) {
                ForEach(Gender.allCases) { g in Text(g.displayName).tag(g) }
            }

            Picker("Type", selection: $draft.clothingType) {
                ForEach(ClothingType.available(for: draft.ageGroup)) { t in Text(t.displayName).tag(t) }
            }
            .onChange(of: draft.clothingType) { _, newType in
                if newType == .shoes { draft.size = nil } else { draft.shoeSize = nil }
            }

            if draft.clothingType == .shoes {
                Picker("Shoe Size", selection: $draft.shoeSize) {
                    Text("Select a size").tag(Optional<ShoeSize>.none)
                    ForEach(ShoeSize.grouped(for: draft.ageGroup), id: \.0) { category, sizes in
                        Section(category.rawValue) {
                            ForEach(sizes) { size in Text(size.displayName).tag(Optional(size)) }
                        }
                    }
                }
            } else {
                Picker("Size", selection: $draft.size) {
                    Text("Select a size").tag(Optional<ClothingSize>.none)
                    ForEach(ClothingSize.grouped(for: draft.ageGroup), id: \.0) { category, sizes in
                        Section(category.rawValue) {
                            ForEach(sizes) { size in Text(size.displayName).tag(Optional(size)) }
                        }
                    }
                }
            }

            if !people.isEmpty {
                Picker("Owner", selection: $draft.ownerID) {
                    Text("None").tag(Optional<UUID>.none)
                    ForEach(people) { p in Text(p.name).tag(Optional(p.id)) }
                }
            }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: $draft.status) {
                ForEach(ItemStatus.allCases) { s in Text(s.displayName).tag(s) }
            }

            if draft.status.isForSelling {
                priceRow(label: "Listing Price", value: $draft.listingPrice)
                if draft.status == .sold {
                    HStack {
                        Text("Sale Price")
                        Spacer()
                        TextField("$0.00", value: $draft.salePrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }
            }

            if draft.status.isForDonating {
                priceRow(label: "Donation Value", value: $draft.donationValue)
            }
        }
    }

    private func priceRow(label: String, value: Binding<Double?>) -> some View {
        HStack {
            Text(label)
            Spacer()
            if isEstimatingPrice {
                ProgressView().scaleEffect(0.8)
            } else if aiEnabled {
                Button { Task { await estimatePrice() } } label: {
                    Image(systemName: "wand.and.stars").foregroundStyle(.purple)
                }
                .buttonStyle(.borderless)
            }
            TextField("$0.00", value: value, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(maxWidth: 100)
        }
    }

    private var locationSection: some View {
        Section("Location") {
            Picker("Location", selection: $draft.locationID) {
                Text("None").tag(Optional<UUID>.none)
                ForEach(locations) { l in Text(l.displayLabel).tag(Optional(l.id)) }
            }
            .disabled(locations.isEmpty)

            Button { showingAddLocation = true } label: {
                Label("New Location…", systemImage: "plus")
            }
        }
    }

    // MARK: - Actions

    private func loadPhotos(from items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    photoData.append(data)
                }
            }
            selectedPhotos = []
        }
    }

    private func generateDescription() async {
        isGeneratingDescription = true
        defer { isGeneratingDescription = false }
        if let result = await AIService.shared.generateDescription(photoData: photoData) {
            draft.itemDescription = result
        }
    }

    private func estimatePrice() async {
        isEstimatingPrice = true
        defer { isEstimatingPrice = false }

        let brand = draft.brand
        let type = draft.clothingType
        let condition = draft.condition
        let size = draft.size
        let shoeSize = draft.shoeSize
        let ageGroup = draft.ageGroup

        if draft.status.isForDonating {
            if let price = await AIService.shared.estimateDonationValue(
                brand: brand,
                type: type,
                condition: condition,
                size: size,
                shoeSize: shoeSize,
                ageGroup: ageGroup
            ) {
                draft.donationValue = price
            }
        } else if draft.status.isForSelling {
            if let price = await AIService.shared.estimatePrice(
                brand: brand,
                type: type,
                condition: condition,
                size: size,
                shoeSize: shoeSize,
                ageGroup: ageGroup
            ) {
                draft.listingPrice = price
            }
        }
    }

    private func save() {
        let item: ClothingItem
        if let existing = existingItem {
            item = existing
        } else {
            item = ClothingItem(context: managedObjectContext)
        }

        item.itemDescription = draft.itemDescription
        item.brand    = draft.brand
        item.color    = draft.color
        item.status   = draft.status
        item.clothingType = draft.clothingType
        item.ageGroup = draft.ageGroup
        item.gender   = draft.gender
        item.condition = draft.condition
        item.size     = draft.size
        item.shoeSize = draft.shoeSize
        item.listingPrice  = draft.listingPrice.map  { NSNumber(value: $0) }
        item.donationValue = draft.donationValue.map { NSNumber(value: $0) }
        item.salePrice     = draft.salePrice.map     { NSNumber(value: $0) }
        item.updatedAt    = Date()

        item.owner    = people.first    { $0.id == draft.ownerID }
        item.location = locations.first { $0.id == draft.locationID }

        // Replace all photos
        if let existing = item.photos as? Set<ItemPhoto> {
            existing.forEach { managedObjectContext.delete($0) }
        }
        item.photos = NSSet()
        for (index, data) in photoData.enumerated() {
            let photo = ItemPhoto(context: managedObjectContext)
            photo.imageData  = data
            photo.sortOrder  = Int64(index)
            photo.item       = item
        }

        try? managedObjectContext.save()
        dismiss()
    }
}

// MARK: - Camera

struct CameraView: UIViewControllerRepresentable {
    var onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate   = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data  = image.jpegData(compressionQuality: 0.85) {
                parent.onCapture(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Draft

struct ItemDraft {
    var itemDescription: String = ""
    var brand: String           = ""
    var color: String           = ""
    var status: ItemStatus      = .keep
    var clothingType: ClothingType = .shirts
    var ageGroup: AgeGroup      = .adult
    var gender: Gender          = .unisex
    var condition: ItemCondition = .good
    var size: ClothingSize?     = nil
    var shoeSize: ShoeSize?     = nil
    var listingPrice: Double?   = nil
    var donationValue: Double?  = nil
    var salePrice: Double?      = nil
    var ownerID: UUID?          = nil
    var locationID: UUID?       = nil

    init() {}

    init(from item: ClothingItem) {
        itemDescription = item.itemDescription
        brand           = item.brand
        color           = item.color
        status          = item.status
        clothingType    = item.clothingType
        ageGroup        = item.ageGroup
        gender          = item.gender
        condition       = item.condition
        size            = item.size
        shoeSize        = item.shoeSize
        listingPrice    = item.listingPrice?.doubleValue
        donationValue   = item.donationValue?.doubleValue
        salePrice       = item.salePrice?.doubleValue
        ownerID         = item.owner?.id
        locationID      = item.location?.id

        // Legacy items stored donation amount in listingPrice before donationValue existed.
        if item.status.isForDonating, donationValue == nil, let legacy = item.listingPrice?.doubleValue {
            donationValue = legacy
        }
    }
}
