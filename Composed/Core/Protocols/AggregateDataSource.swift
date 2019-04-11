public protocol AggregateDataSource: LifecycleObservingDataSource {
    var children: [DataSource] { get }
    var descendants: [DataSource] { get }

    func insert(dataSource: DataSource, at index: Int)
    func remove(dataSource: DataSource)
    func removeAll()

    /// The indexPath of the element satisfying `predicate`. Returns nil if the predicate cannot be satisfied
    ///
    /// - Parameter predicate: The predicate to use
    /// - Returns: An `IndexPath` if the specified predicate can be satisfied, nil otherwise
    func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath?

    func dataSourceFor(global section: Int) -> (dataSource: DataSource, localSection: Int)
    func dataSourceFor(global indexPath: IndexPath) -> (dataSource: DataSource, localIndexPath: IndexPath)
}

extension DataSource {

    func dataSourceFor(global section: Int) -> (dataSource: DataSource, localSection: Int) {
        return (self as? AggregateDataSource)?.dataSourceFor(global: section) ?? (self, section)
    }

    func dataSourceFor(global indexPath: IndexPath) -> (dataSource: DataSource, localIndexPath: IndexPath) {
        return (self as? AggregateDataSource)?.dataSourceFor(global: indexPath) ?? (self, indexPath)
    }

}

public extension AggregateDataSource {

    var isEmpty: Bool {
        return children.lazy.allSatisfy { $0.isEmpty }
    }
    
}

public protocol SearchableDataSource: DataSource {
    /// The indexPath of the element satisfying `predicate`. Returns nil if the predicate cannot be satisfied
    ///
    /// - Parameter predicate: The predicate to use
    /// - Returns: An `IndexPath` if the specified predicate can be satisfied, nil otherwise
    func indexPath<Element>(where predicate: @escaping (Element) -> Bool) -> IndexPath?
}
