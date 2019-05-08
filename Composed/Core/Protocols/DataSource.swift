import Foundation
// MARK: Changes to this delegate require careful consideration
// MARK: -
public protocol DataSourceUpdateDelegate: class {
    func dataSource(_ dataSource: DataSource, performUpdates changeDetails: ComposedChangeDetails)
    func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceInvalidationContext)
    func dataSource(_ dataSource: DataSource, sectionFor localSection: Int) -> (dataSource: DataSource, globalSection: Int)
}

// MARK: -

/// Represents a definition of a DataSource for representing a single source of data and its associated visual representations
public protocol DataSource: class, CustomStringConvertible, CustomDebugStringConvertible {

    /// The delegate responsible for responding to update events. This is generally used for update propogation. The 'root' DataSource's delegate will generally be a `UIViewController`
    var updateDelegate: DataSourceUpdateDelegate? { get set }

    /// The number of sections this DataSource contains
    var numberOfSections: Int { get }

    /// The number of elements contained in the specified section
    ///
    /// - Parameter section: The section index
    /// - Returns: The number of elements contained in the specified section
    func numberOfElements(in section: Int) -> Int

    /// The indexPath of the element satisfying `predicate`. Returns nil if the predicate cannot be satisfied
    ///
    /// - Parameter predicate: The predicate to use
    /// - Returns: An `IndexPath` if the specified predicate can be satisfied, nil otherwise
    func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath?

    func localSection(for section: Int) -> (dataSource: DataSource, localSection: Int)

}

public extension DataSource {

    var isEmpty: Bool {
        return (0..<numberOfSections)
            .lazy
            .allSatisfy { numberOfElements(in: $0) == 0 }
    }

    var isEmbedded: Bool {
        guard let delegate = updateDelegate else { return false }
        return delegate is _EmbeddedDataSource
    }

    var isRoot: Bool {
        return !(updateDelegate is DataSource)
    }

    /// Returns true if the rootDataSource's updateDelegate is non-nil
    var isActive: Bool {
        var dataSource: DataSource = self

        while !dataSource.isRoot, let parent = dataSource.updateDelegate as? DataSource {
            dataSource = parent
        }

        return dataSource.updateDelegate != nil
    }

    func descendants(in sections: IndexSet) -> [DataSource] {
        return sections.compactMap { self.localSection(for: $0).dataSource }
    }

}

extension DataSource {

    public var description: String {
        return DataSourceHashableWrapper(self).description
    }

    public var debugDescription: String {
        return DataSourceHashableWrapper(self).debugDescription
    }

}
