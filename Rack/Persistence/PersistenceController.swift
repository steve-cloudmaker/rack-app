import CoreData
import CloudKit

final class PersistenceController: @unchecked Sendable {
    static let shared = PersistenceController()

    /// Must match SwiftData's default CloudKit store configuration so existing iCloud data syncs.
    private static let privateConfigurationName = "Default"
    private static let sharedConfigurationName = "Shared"

    let container: NSPersistentCloudKitContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private let privateStoreURL: URL
    private let sharedStoreURL: URL

    var privatePersistentStore: NSPersistentStore? {
        container.persistentStoreCoordinator.persistentStores.first { $0.url == privateStoreURL }
    }

    var sharedPersistentStore: NSPersistentStore? {
        container.persistentStoreCoordinator.persistentStores.first { $0.url == sharedStoreURL }
    }

    init() {
        let model = PersistenceController.makeModel()
        container = NSPersistentCloudKitContainer(name: "Cedar", managedObjectModel: model)

        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        privateStoreURL = appSupport.appendingPathComponent("Cedar-private.sqlite")
        sharedStoreURL  = appSupport.appendingPathComponent("Cedar-shared.sqlite")

        let privateDesc = NSPersistentStoreDescription(url: privateStoreURL)
        privateDesc.configuration = Self.privateConfigurationName
        privateDesc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.stevedaurora.cedar"
        )
        privateDesc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateDesc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        let sharedDesc = NSPersistentStoreDescription(url: sharedStoreURL)
        sharedDesc.configuration = Self.sharedConfigurationName
        let sharedCKOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.stevedaurora.cedar"
        )
        sharedCKOptions.databaseScope = .shared
        sharedDesc.cloudKitContainerOptions = sharedCKOptions
        sharedDesc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        sharedDesc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.persistentStoreDescriptions = [privateDesc, sharedDesc]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("[Cedar] Failed to load persistent stores: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - CloudKit sync

    func setupCloudKitSync() {
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container,
            queue: .main
        ) { notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else { return }
            Task { @MainActor in
                CloudKitSyncMonitor.shared.handleCloudKitEvent(event)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.container.viewContext.perform {
                self.container.viewContext.refreshAllObjects()
            }
        }
    }

    // MARK: - Model

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let clothingItem    = NSEntityDescription()
        let person          = NSEntityDescription()
        let storageLocation = NSEntityDescription()
        let itemPhoto       = NSEntityDescription()

        clothingItem.name                   = "ClothingItem"
        clothingItem.managedObjectClassName = "Cedar.ClothingItem"
        person.name                         = "Person"
        person.managedObjectClassName       = "Cedar.Person"
        storageLocation.name                = "StorageLocation"
        storageLocation.managedObjectClassName = "Cedar.StorageLocation"
        itemPhoto.name                      = "ItemPhoto"
        itemPhoto.managedObjectClassName    = "Cedar.ItemPhoto"

        func attr(_ name: String, _ type: NSAttributeType, optional: Bool = false, default val: Any? = nil) -> NSAttributeDescription {
            let d = NSAttributeDescription()
            d.name = name; d.attributeType = type; d.isOptional = optional; d.defaultValue = val
            return d
        }

        clothingItem.properties = [
            attr("id",             .UUIDAttributeType,       default: UUID()),
            attr("createdAt",      .dateAttributeType,       default: Date()),
            attr("updatedAt",      .dateAttributeType,       default: Date()),
            attr("itemDescription",.stringAttributeType,  default: ""),
            attr("brand",          .stringAttributeType,  default: ""),
            attr("color",          .stringAttributeType,  default: ""),
            attr("statusRaw",      .stringAttributeType,  default: ItemStatus.keep.rawValue),
            attr("clothingTypeRaw",.stringAttributeType,  default: ClothingType.shirts.rawValue),
            attr("ageGroupRaw",    .stringAttributeType,  default: AgeGroup.adult.rawValue),
            attr("genderRaw",      .stringAttributeType,  default: Gender.unisex.rawValue),
            attr("conditionRaw",   .stringAttributeType,  default: ItemCondition.good.rawValue),
            attr("sizeRaw",        .stringAttributeType,  default: ""),
            attr("shoeSizeRaw",    .stringAttributeType,  default: ""),
            attr("listingPrice",   .doubleAttributeType,  optional: true),
            attr("donationValue",  .doubleAttributeType,  optional: true),
            attr("salePrice",      .doubleAttributeType,  optional: true),
            attr("saleDate",       .dateAttributeType,   optional: true),
            attr("donatedDate",    .dateAttributeType,   optional: true),
        ]

        person.properties = [
            attr("id",        .UUIDAttributeType,  default: UUID()),
            attr("name",      .stringAttributeType, default: ""),
            attr("createdAt", .dateAttributeType,  default: Date()),
        ]

        storageLocation.properties = [
            attr("id",        .UUIDAttributeType,  default: UUID()),
            attr("name",      .stringAttributeType, default: ""),
            attr("rack",      .stringAttributeType, default: ""),
            attr("row",       .stringAttributeType, default: ""),
            attr("createdAt", .dateAttributeType,  default: Date()),
        ]

        let imageDataAttr = NSAttributeDescription()
        imageDataAttr.name = "imageData"
        imageDataAttr.attributeType = .binaryDataAttributeType
        imageDataAttr.isOptional = true
        imageDataAttr.allowsExternalBinaryDataStorage = true

        itemPhoto.properties = [
            attr("id",        .UUIDAttributeType,  default: UUID()),
            attr("sortOrder", .integer64AttributeType, default: 0),
            imageDataAttr,
        ]

        // ClothingItem ↔ ItemPhoto (cascade delete)
        let photosRel       = NSRelationshipDescription()
        photosRel.name      = "photos"
        photosRel.destinationEntity = itemPhoto
        photosRel.isOptional = true
        photosRel.deleteRule = .cascadeDeleteRule
        photosRel.minCount  = 0; photosRel.maxCount = 0

        let photoToItemRel       = NSRelationshipDescription()
        photoToItemRel.name      = "item"
        photoToItemRel.destinationEntity = clothingItem
        photoToItemRel.isOptional = true
        photoToItemRel.deleteRule = .nullifyDeleteRule
        photoToItemRel.maxCount  = 1

        photosRel.inverseRelationship    = photoToItemRel
        photoToItemRel.inverseRelationship = photosRel

        // ClothingItem ↔ Person (nullify)
        let ownerRel       = NSRelationshipDescription()
        ownerRel.name      = "owner"
        ownerRel.destinationEntity = person
        ownerRel.isOptional = true
        ownerRel.deleteRule = .nullifyDeleteRule
        ownerRel.maxCount  = 1

        let personItemsRel       = NSRelationshipDescription()
        personItemsRel.name      = "items"
        personItemsRel.destinationEntity = clothingItem
        personItemsRel.isOptional = true
        personItemsRel.deleteRule = .nullifyDeleteRule
        personItemsRel.minCount  = 0; personItemsRel.maxCount = 0

        ownerRel.inverseRelationship      = personItemsRel
        personItemsRel.inverseRelationship = ownerRel

        // ClothingItem ↔ StorageLocation (nullify)
        let locationRel       = NSRelationshipDescription()
        locationRel.name      = "location"
        locationRel.destinationEntity = storageLocation
        locationRel.isOptional = true
        locationRel.deleteRule = .nullifyDeleteRule
        locationRel.maxCount  = 1

        let locationItemsRel       = NSRelationshipDescription()
        locationItemsRel.name      = "items"
        locationItemsRel.destinationEntity = clothingItem
        locationItemsRel.isOptional = true
        locationItemsRel.deleteRule = .nullifyDeleteRule
        locationItemsRel.minCount  = 0; locationItemsRel.maxCount = 0

        locationRel.inverseRelationship      = locationItemsRel
        locationItemsRel.inverseRelationship = locationRel

        clothingItem.properties    += [photosRel, ownerRel, locationRel]
        person.properties          += [personItemsRel]
        storageLocation.properties += [locationItemsRel]
        itemPhoto.properties       += [photoToItemRel]

        let all = [clothingItem, person, storageLocation, itemPhoto]
        model.entities = all
        model.setEntities(all, forConfigurationName: Self.privateConfigurationName)
        model.setEntities(all, forConfigurationName: Self.sharedConfigurationName)

        return model
    }

    // MARK: - Sharing

    func prepareShare() async throws -> ShareConfig {
        guard let privateStore = privatePersistentStore else {
            throw SharingError.shareCreationFailed
        }

        // Re-use existing share if present
        if let existing = (try? container.fetchShares(in: privateStore))?.first {
            return ShareConfig(
                share: existing,
                container: CKContainer(identifier: "iCloud.com.stevedaurora.cedar")
            )
        }

        let request = NSFetchRequest<ClothingItem>(entityName: "ClothingItem")
        request.fetchLimit = 1
        request.affectedStores = [privateStore]
        let items = try viewContext.fetch(request)
        guard let item = items.first else { throw SharingError.noItems }

        return try await withCheckedThrowingContinuation { continuation in
            container.share([item], to: nil) { [weak self] _, share, ckContainer, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let share, let ckContainer else {
                    continuation.resume(throwing: SharingError.shareCreationFailed)
                    return
                }
                share[CKShare.SystemFieldKey.title] = "Cedar Closet"
                share.publicPermission = .readWrite
                DispatchQueue.main.async {
                    try? self?.viewContext.save()
                    continuation.resume(returning: ShareConfig(share: share, container: ckContainer))
                }
            }
        }
    }

    func acceptShare(_ metadata: CKShare.Metadata) {
        guard let sharedStore = sharedPersistentStore else { return }
        container.acceptShareInvitations(from: [metadata], into: sharedStore) { _, error in
            if let error { print("[Cedar] acceptShare error: \(error)") }
        }
    }

    enum SharingError: LocalizedError {
        case noItems, shareCreationFailed
        var errorDescription: String? {
            switch self {
            case .noItems:             "Add at least one item before sharing your closet."
            case .shareCreationFailed: "Failed to create share. Please try again."
            }
        }
    }
}

struct ShareConfig: Identifiable {
    let id = UUID()
    let share: CKShare
    let container: CKContainer
}
