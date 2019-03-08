public protocol CollectionDataSource: DataSource, DataStoreDelegate {
    associatedtype Store: DataStore
    func element(at indexPath: IndexPath) -> Store.Element
}

extension DataSourceLifecycleObserving where Self: CollectionDataSource {
    public func prepare() { }
    public func invalidate() { }
    public func didBecomeActive() { }
    public func willResignActive() { }
}

public extension CollectionDataSource {

    subscript(indexPath: IndexPath) -> Store.Element {
        return element(at: indexPath)
    }

}

extension CollectionDataSource where Store.Element: Equatable {

    func indexPath(of element: Store.Element) -> IndexPath? {
        return indexPath { other in
            guard let other = other as? Store.Element else { return false }
            return other == element
        }
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
