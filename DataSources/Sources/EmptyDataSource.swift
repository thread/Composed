public final class EmptyDataSource: DataSource {

    public var updateDelegate: DataSourceUpdateDelegate?
    public var numberOfSections: Int { return 0 }
    public func numberOfItems(inSection section: Int) -> Int { return 0 }
    public func indexPath(where predicate: (Any) -> Bool) -> IndexPath? { return nil }

}
