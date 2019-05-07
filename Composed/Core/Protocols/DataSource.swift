import Foundation
// MARK: Changes to this delegate require careful consideration
// MARK: -
public protocol DataSourceUpdateDelegate: class {
    func dataSource(_ dataSource: DataSource, willPerform updates: [DataSourceUpdate])
    func dataSource(_ dataSource: DataSource, didPerform updates: [DataSourceUpdate])
    
    func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet)
    func dataSource(_ dataSource: DataSource, didDeleteSections sections: IndexSet)
    func dataSource(_ dataSource: DataSource, didUpdateSections sections: IndexSet)
    func dataSource(_ dataSource: DataSource, didMoveSection from: Int, to: Int)

    func dataSource(_ dataSource: DataSource, didInsertIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didDeleteIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didUpdateIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didMoveFromIndexPath from: IndexPath, toIndexPath to: IndexPath)

    func dataSourceDidReload(_ dataSource: DataSource)
    func dataSource(_ dataSource: DataSource, performBatchUpdates updates: () -> Void, completion: ((Bool) -> Void)?)
    func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceInvalidationContext)

    func dataSource(_ dataSource: DataSource, sectionFor localSection: Int) -> (dataSource: DataSource, globalSection: Int)
    
}

public extension DataSourceUpdateDelegate {
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataSource(_ dataSource: DataSource, globalFor local: IndexPath) -> (dataSource: DataSource, globalIndexPath: IndexPath) { fatalError() }
    @available(*, deprecated, renamed: "dataSource(_:sectionFor:)", message: "Method has been named. Calling this method will now result in a fatalError")
    func dataSource(_ dataSource: DataSource, globalFor local: Int) -> (dataSource: DataSource, globalSection: Int) { fatalError() }
}

public extension DataSource {
    @available(*, deprecated, renamed: "localSection(for:)")
    func dataSourceFor(global section: Int) -> (dataSource: DataSource, localSection: Int) { fatalError() }
    @available(*, deprecated, message: "Use localSection(for:) – Map the section, then set indexPath.item manually, it remains unchanged")
    func dataSourceFor(global indexPath: IndexPath) -> (dataSource: DataSource, localIndexPath: IndexPath) { fatalError() }
}

// MARK: -

/// Represents a definition of a DataSource for representing a single source of data and its associated visual representations
public protocol DataSource: class {

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

}

public extension DataSource {

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

}
