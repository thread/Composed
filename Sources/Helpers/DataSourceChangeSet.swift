import Foundation

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
