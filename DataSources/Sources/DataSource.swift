public protocol DataSourceUpdateDelegate: class {
    func dataSource(_ dataSource: DataSource, willPerform updates: [DataSourceUpdate])
    func dataSource(_ dataSource: DataSource, didPerform updates: [DataSourceUpdate])

    func dataSourceDidReload(_ dataSource: DataSource)
    func dataSource(_ dataSource: DataSource, performBatchUpdates updates: () -> Void, completion: ((Bool) -> Void)?)
    
    func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet)
    func dataSource(_ dataSource: DataSource, didDeleteSections sections: IndexSet)
    func dataSource(_ dataSource: DataSource, didUpdateSections sections: IndexSet)
    func dataSource(_ dataSource: DataSource, didMoveSection from: Int, to: Int)

    func dataSource(_ dataSource: DataSource, didInsertIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didDeleteIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didUpdateIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didMoveFromIndexPath from: IndexPath, toIndexPath to: IndexPath)
}

public protocol DataSource: class {
    var updateDelegate: DataSourceUpdateDelegate? { get set }

    var title: String? { get }
    var image: UIImage? { get }

    var numberOfSections: Int { get }
    func numberOfItems(inSection section: Int) -> Int

    func didBecomeActive()
    func willResignActive()

    func setEditing(_ editing: Bool, animated: Bool)
    func indexPath(where predicate: (Any) -> Bool) -> IndexPath?
}

public extension DataSource {

    var isRoot: Bool { return !(updateDelegate is DataSource) }
    var title: String? { return nil }
    var image: UIImage? { return nil }
    var numberOfSections: Int { return 1 }

    var isEmpty: Bool {
        return (0..<numberOfSections)
            .map { numberOfItems(inSection: $0) }
            .reduce(0, { $0 + $1 }) == 0
    }

    func didBecomeActive() { /* do nothing by default */ }
    func willResignActive() { /* do nothing by default */ }
    func setEditing(_ editing: Bool, animated: Bool) { /* do nothing by default */ }

}
