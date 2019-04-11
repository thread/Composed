import Foundation

public protocol CollectionDataSource: SearchableDataSource, DataStoreDelegate {
    associatedtype Store: DataStore
    func element(at indexPath: IndexPath) -> Store.Element
}

/// The indexPath of the element satisfying `predicate`. Returns nil if the predicate cannot be satisfied
///
/// - Parameter predicate: The predicate to use
/// - Returns: An `IndexPath` if the specified predicate can be satisfied, nil otherwise
//func indexPath(where predicate: @escaping (Store.Element) -> Bool) -> IndexPath?

public extension CollectionDataSource {
    func indexPath<Element>(where predicate: @escaping (Element) -> Bool) -> IndexPath? {
        return indexPath { (element: Store.Element) in
            guard let element = element as? Element else { return false }
            return predicate(element)
        }
    }
}

public extension CollectionDataSource {

    subscript(indexPath: IndexPath) -> Store.Element {
        return element(at: indexPath)
    }

}

extension CollectionDataSource where Store.Element: Equatable {

    func indexPath(of element: Store.Element) -> IndexPath? {
        return indexPath { $0 == element }
    }

}

extension CollectionDataSource {

    public func dataStore(willPerform updates: [DataSourceUpdate]) {
        updateDelegate?.dataSource(self, willPerform: updates)
    }

    public func dataStore(didPerform updates: [DataSourceUpdate]) {
        updateDelegate?.dataSource(self, didPerform: updates)
    }

    public func dataStore(didInsertSections sections: IndexSet) {
        updateDelegate?.dataSource(self, didInsertSections: sections)
    }

    public func dataStore(didDeleteSections sections: IndexSet) {
        updateDelegate?.dataSource(self, didDeleteSections: sections)
    }

    public func dataStore(didUpdateSections sections: IndexSet) {
        updateDelegate?.dataSource(self, didUpdateSections: sections)
    }

    public func dataStore(didMoveSection from: Int, to: Int) {
        updateDelegate?.dataSource(self, didMoveSection: from, to: to)
    }

    public func dataStore(didInsertIndexPaths indexPaths: [IndexPath]) {
        updateDelegate?.dataSource(self, didInsertIndexPaths: indexPaths)
    }

    public func dataStore(didDeleteIndexPaths indexPaths: [IndexPath]) {
        updateDelegate?.dataSource(self, didDeleteIndexPaths: indexPaths)
    }

    public func dataStore(didUpdateIndexPaths indexPaths: [IndexPath]) {
        updateDelegate?.dataSource(self, didUpdateIndexPaths: indexPaths)
    }

    public func dataStore(didMoveFromIndexPath from: IndexPath, toIndexPath to: IndexPath) {
        updateDelegate?.dataSource(self, didMoveFromIndexPath: from, toIndexPath: to)
    }

    public func dataStoreDidReload() {
        updateDelegate?.dataSourceDidReload(self)
    }

    public func dataStore(performBatchUpdates updates: () -> Void, completion: ((Bool) -> Void)?) {
        updateDelegate?.dataSource(self, performBatchUpdates: updates, completion: completion)
    }

}
