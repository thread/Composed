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

public protocol DataSource: class {
    var updateDelegate: DataSourceUpdateDelegate? { get set }

    var title: String? { get }
    var image: UIImage? { get }

    var numberOfSections: Int { get }
    func numberOfElements(inSection section: Int) -> Int

    func didBecomeActive()
    func willResignActive()

    func indexPath(where predicate: (Any) -> Bool) -> IndexPath?
    func localIndexPath(forGlobal indexPath: IndexPath) -> IndexPath?

    func layoutStrategy(for section: Int) -> FlowLayoutStrategy

    func cellType(for indexPath: IndexPath) -> DataReusableView.Type
    func supplementType(for indexPath: IndexPath, ofKind kind: String) -> DataReusableView.Type
    func prepare(cell: DataSourceCell, at indexPath: IndexPath)
    func prepare(supplementaryView: UICollectionReusableView, at indexPath: IndexPath, of kind: String)
}

public extension DataSource {

    var isRoot: Bool { return !(updateDelegate is DataSource) }
    var title: String? { return nil }
    var image: UIImage? { return nil }
    var numberOfSections: Int { return 1 }

    var isEmpty: Bool {
        return (0..<numberOfSections)
            .lazy
            .allSatisfy { numberOfElements(inSection: $0) > 0 }
    }

    func didBecomeActive() { /* do nothing by default */ }
    func willResignActive() { /* do nothing by default */ }

}
