public protocol AggregateDataSource: LifecycleObservingDataSource {
    var children: [DataSource] { get }
    var descendants: [DataSource] { get }

    func insert(dataSource: DataSource, at index: Int)
    func remove(dataSource: DataSource)
    func removeAll()
}

public extension AggregateDataSource {

    var isEmpty: Bool {
        return children.lazy.allSatisfy { $0.isEmpty }
    }
    
}
