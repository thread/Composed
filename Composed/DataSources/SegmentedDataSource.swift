open class SegmentedDataSource: AggregateDataSource {

    public private(set) var children: [DataSource] = []
    public var updateDelegate: DataSourceUpdateDelegate?

    public func setDataSources(_ dataSources: [DataSource], changeset: DataSourceChangeset? = nil) {

    }

    public func insert(dataSource: DataSource, at index: Int) {

    }

    public func remove(dataSource: DataSource) {

    }

    public func removeAll() {

    }

    public func numberOfElements(inSection section: Int) -> Int {
        return 0
    }

    public func indexPath(where predicate: (Any) -> Bool) -> IndexPath? {
        return nil
    }

    public func localIndexPath(forGlobal indexPath: IndexPath) -> IndexPath? {
        return nil
    }

    public func viewType(for indexPath: IndexPath, ofKind kind: String?) -> DataReusableView.Type {
        fatalError()
    }

    public func layoutStrategy(for section: Int) -> FlowLayoutStrategy {
        fatalError()
    }

    public func prepare(cell: DataSourceCell, at indexPath: IndexPath) {
        
    }




}
