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
}
// MARK: -

public struct DataSourceSectionMetrics {

    public let columnCount: Int
    public let insets: UIEdgeInsets
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat

    public init(columnCount: Int, insets: UIEdgeInsets, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        self.columnCount = columnCount
        self.insets = insets
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

}

public protocol DataSourceCellEditing {
    var isEditing: Bool { get }
    func setEditing(_ editing: Bool, animated: Bool)
}

public protocol DataSourceEditing {
    var isEditing: Bool { get }
    func setEditing(_ editing: Bool, animated: Bool)
    func supportsEditing(for indexPath: IndexPath) -> Bool
}

public protocol DataSourceSelecting {
    func supportsSelection(for indexPath: IndexPath) -> Bool
    func selectElement(for indexPath: IndexPath)
    func deselectElement(for indexPath: IndexPath)
}

public extension DataSourceSelecting {
    func supportsSelection(for indexPath: IndexPath) -> Bool { return true }
    func deselectElement(for indexPath: IndexPath) { }
}

public protocol DataSourceUIProviding {
    func metrics(for section: Int) -> DataSourceSectionMetrics
    func cellConfiguration(for indexPath: IndexPath) -> CellConfiguration
    func headerConfiguration(for section: Int) -> HeaderFooterConfiguration?
    func footerConfiguration(for section: Int) -> HeaderFooterConfiguration?
}

public extension DataSourceUIProviding {
    func headerConfiguration(for section: Int) -> HeaderFooterConfiguration? { return nil }
    func footerConfiguration(for section: Int) -> HeaderFooterConfiguration? { return nil }
}

public protocol DataSourceSelectable {
    func didSelect(indexPath: IndexPath)
}

/// Represents a definition of a DataSource for representing a single source of data and its associated visual representations
public protocol DataSource: class {

    /// The delegate responsible for responding to update events. This is generally used for update propogation. The 'root' DataSource's delegate will generally be a `UIViewController`
    var updateDelegate: DataSourceUpdateDelegate? { get set }

    /// Called when the DataSource becomes active
    func didBecomeActive()

    /// Called when the DataSource is no longer active
    func willResignActive()

    func invalidate()

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

    func dataSourceFor(global section: Int) -> (dataSource: DataSource, localSection: Int)
    func dataSourceFor(global indexPath: IndexPath) -> (dataSource: DataSource, localIndexPath: IndexPath)

}

public extension DataSource {

    var isRoot: Bool {
        return !(updateDelegate is DataSource)
            || self is GlobalDataSource
    }

    var isEmpty: Bool {
        return (0..<numberOfSections)
            .lazy
            .allSatisfy { numberOfElements(in: $0) == 0 }
    }

}
