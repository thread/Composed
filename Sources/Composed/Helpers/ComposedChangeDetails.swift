import Foundation

public struct ComposedChangeDetails {

    public var hasSectionChanges: Bool {
        return !insertedSections.isEmpty
            || !updatedSections.isEmpty
            || !removedSections.isEmpty
            || !movedSections.isEmpty
    }

    public var hasIncrementalChanges: Bool = true {
        didSet {
            let updatesAllowed = oldValue
            if !updatesAllowed {
                // if updates were previously disabled, we don't allow them to be re-enabled, so force back to false
                hasIncrementalChanges = false
            }
        }
    }

    public var removedSections = IndexSet()
    public var removedIndexPaths: [IndexPath] = []
    public var insertedSections = IndexSet()
    public var insertedIndexPaths: [IndexPath] = []
    public var updatedSections = IndexSet()
    public var updatedIndexPaths: [IndexPath] = []

    public var movedSections: [(source: Int, target: Int)] = []
    public var movedIndexPaths: [(source: IndexPath, target: IndexPath)] = []

    public func enumerateMovedSections(_ handler: (Int, Int) -> Void) {
        movedSections.forEach(handler)
    }

    public func enumerateMovedIndexPaths(_ handler: (IndexPath, IndexPath) -> Void) {
        movedIndexPaths.forEach(handler)
    }

    public init(hasIncrementalChanges: Bool) {
        self.hasIncrementalChanges = hasIncrementalChanges
    }

}

public extension ComposedChangeDetails {

    init(changesets: [DataSourceChangeset]? = nil) {
        removedSections = IndexSet(changesets?.flatMap { $0.deletedSections } ?? [])
        removedIndexPaths = changesets?.flatMap { $0.deletedIndexPaths } ?? []
        insertedSections = IndexSet(changesets?.flatMap { $0.insertedSections } ?? [])
        insertedIndexPaths = changesets?.flatMap { $0.insertedIndexPaths } ?? []
        updatedSections = IndexSet(changesets?.flatMap { $0.updatedSections } ?? [])
        updatedIndexPaths = changesets?.flatMap { $0.updatedIndexPaths } ?? []
        movedSections = changesets?.flatMap { $0.movedSections } ?? []
        movedIndexPaths = changesets?.flatMap { $0.movedIndexPaths } ?? []
    }

}
