import Foundation

public struct ComposedChangeDetails {

    private var _hasIncrementalChanges: Bool = true
    public var hasIncrementalChanges: Bool {
        get { return _hasIncrementalChanges }
        set {
            // once this has been set to false we don't allow updates
            guard _hasIncrementalChanges else { return }
            _hasIncrementalChanges = newValue
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
        _hasIncrementalChanges = hasIncrementalChanges
    }

}

internal extension ComposedChangeDetails {

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
