import SwiftUI
import SwiftData
import PhotosUI

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var people: [Person]
    @Query private var locations: [StorageLocation]

    // Editing state — nil item means we're creating
    private let existingItem: ClothingItem?
    @State private var draft = ItemDraft()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var isGeneratingDescription = false

    init(item: ClothingItem?) {
        self.existingItem = item
        if let item {
            _draft = State(initialValue: ItemDraft(from: item))
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
                        PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5 - photoData.count, matching: .images) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(width: 100, height: 100)
                                .overlay(Image(systemName: "plus").font(.title2).foregroundStyle(.secondary))
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
        .onChange(of: selectedPhotos) { _, newItems in
            loadPhotos(from: newItems)
        }
    }

    private var coreDetailsSection: some View {
        Section("Details") {
            HStack {
                TextField("Description", text: $draft.itemDescription)
                if isGeneratingDescription {
                    ProgressView().scaleEffect(0.8)
                } else if !photoData.isEmpty {
                    Button {
                        Task { await generateDescription() }
                    } label: {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.purple)
                    }
                    .buttonStyle(.borderless)
                }
            }
            TextField("Brand", text: $draft.brand)
            TextField("Color", text: $draft.color)
            Picker("Condition", selection: $draft.condition) {
                ForEach(ItemCondition.allCases) { condition in
                    Text(condition.displayName).tag(condition)
                }
            }
        }
    }

    private var classificationSection: some View {
        Section("Classification") {
            Picker("Age Group", selection: $draft.ageGroup) {
                ForEach(AgeGroup.allCases) { group in
                    Text(group.displayName).tag(group)
                }
            }
            .onChange(of: draft.ageGroup) { _, newGroup in
                if draft.clothingType.isKidsOnly && newGroup == .adult {
                    draft.clothingType = .shirts
                }
                if let size = draft.size, !ClothingSize.available(for: newGroup).contains(size) {
                    draft.size = nil
                }
            }

            Picker("Gender", selection: $draft.gender) {
                ForEach(Gender.allCases) { gender in
                    Text(gender.displayName).tag(gender)
                }
            }

            Picker("Type", selection: $draft.clothingType) {
                ForEach(ClothingType.available(for: draft.ageGroup)) { type in
                    Text(type.displayName).tag(type)
                }
            }

            Picker("Size", selection: $draft.size) {
                Text("Select a size").tag(Optional<ClothingSize>.none)
                ForEach(ClothingSize.grouped(for: draft.ageGroup), id: \.0) { category, sizes in
                    Section(category.rawValue) {
                        ForEach(sizes) { size in
                            Text(size.displayName).tag(Optional(size))
                        }
                    }
                }
            }

            if !people.isEmpty {
                Picker("Owner", selection: $draft.ownerID) {
                    Text("None").tag(Optional<UUID>.none)
                    ForEach(people) { person in
                        Text(person.name).tag(Optional(person.id))
                    }
                }
            }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: $draft.status) {
                ForEach(ItemStatus.allCases) { status in
                    Text(status.displayName).tag(status)
                }
            }

            if draft.status.isForSelling {
                HStack {
                    Text("Listing Price")
                    Spacer()
                    TextField("$0.00", value: $draft.listingPrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
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
        }
    }

    private var locationSection: some View {
        Section("Location") {
            if locations.isEmpty {
                Text("No locations added yet")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Location", selection: $draft.locationID) {
                    Text("None").tag(Optional<UUID>.none)
                    ForEach(locations) { location in
                        Text(location.displayLabel).tag(Optional(location.id))
                    }
                }
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
        do { isGeneratingDescription = false }
        // AI description generation — implemented in AIService
        // draft.itemDescription = await AIService.shared.generateDescription(photoData: photoData)
    }

    private func save() {
        let item = existingItem ?? ClothingItem()

        // Insert new items before setting any relationships
        if isNew { modelContext.insert(item) }

        item.itemDescription = draft.itemDescription
        item.brand = draft.brand
        item.color = draft.color
        item.status = draft.status
        item.clothingType = draft.clothingType
        item.ageGroup = draft.ageGroup
        item.gender = draft.gender
        item.condition = draft.condition
        item.size = draft.size
        item.listingPrice = draft.listingPrice
        item.salePrice = draft.salePrice
        item.updatedAt = Date()

        item.owner = people.first { $0.id == draft.ownerID }
        item.location = locations.first { $0.id == draft.locationID }

        // Delete old photos, then insert new ones into context before wiring relationship
        item.photos.forEach { modelContext.delete($0) }
        item.photos = []
        for (index, data) in photoData.enumerated() {
            let photo = ItemPhoto(imageData: data, sortOrder: index)
            modelContext.insert(photo)
            item.photos.append(photo)
        }

        dismiss()
    }
}

// MARK: - Draft

struct ItemDraft {
    var itemDescription: String = ""
    var brand: String = ""
    var color: String = ""
    var status: ItemStatus = .keep
    var clothingType: ClothingType = .shirts
    var ageGroup: AgeGroup = .adult
    var gender: Gender = .unisex
    var condition: ItemCondition = .good
    var size: ClothingSize? = nil
    var listingPrice: Double? = nil
    var salePrice: Double? = nil
    var ownerID: UUID? = nil
    var locationID: UUID? = nil

    init() {}

    init(from item: ClothingItem) {
        itemDescription = item.itemDescription
        brand = item.brand
        color = item.color
        status = item.status
        clothingType = item.clothingType
        ageGroup = item.ageGroup
        gender = item.gender
        condition = item.condition
        size = item.size
        listingPrice = item.listingPrice
        salePrice = item.salePrice
        ownerID = item.owner?.id
        locationID = item.location?.id
    }
}
