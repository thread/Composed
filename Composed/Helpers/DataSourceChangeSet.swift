public protocol DataSourceChangeset {
    /// The offsets of deleted sections.
    var deletedSections: [Int] { get }
    /// The offsets of inserted sections.
    var insertedSections: [Int] { get }
    /// The offsets of updated sections.
    var updatedSections: [Int] { get }
    /// The pairs of source and target offset of moved sections.
    var movedSections: [(source: Int, target: Int)] { get }

    /// The paths of deleted elements.
    var deletedIndexPaths: [IndexPath] { get }
    /// The paths of inserted elements.
    var insertedIndexPaths: [IndexPath] { get }
    /// The paths of updated elements.
    var updatedIndexPaths: [IndexPath] { get }
    /// The pairs of source and target path of moved elements.
    var movedIndexPaths: [(source: IndexPath, target: IndexPath)] { get }
}

public enum DataSourceUpdate {
    case deleteSections([Int])
    case insertSections([Int])
    case updateSections([Int])
    case moveSections([(source: Int, target: Int)])

    case deleteIndexPaths([IndexPath])
    case insertIndexPaths([IndexPath])
    case updateIndexPaths([IndexPath])
    case moveIndexPaths([(source: IndexPath, target: IndexPath)])
}

public extension DataSourceChangeset {

    var updates: [DataSourceUpdate] {
        var updates: [DataSourceUpdate] = []

        updates.append(.deleteSections(deletedSections.map { $0 }))
        updates.append(.insertSections(insertedSections.map { $0 }))
        updates.append(.updateSections(updatedSections.map { $0 }))
        updates.append(.moveSections(movedSections.map { $0 }))

        updates.append(.deleteIndexPaths(deletedIndexPaths.map { $0 }))
        updates.append(.insertIndexPaths(insertedIndexPaths.map { $0 }))
        updates.append(.updateIndexPaths(updatedIndexPaths.map { $0 }))
        updates.append(.moveIndexPaths(movedIndexPaths.map { $0 }))

        return updates
    }

}
