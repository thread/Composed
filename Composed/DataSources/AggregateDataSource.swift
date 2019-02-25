public protocol AggregateDataSource: DataSource {
    var activeChildren: [DataSource] { get }
    var descendants: [DataSource] { get }

    func insert(dataSource: DataSource, at index: Int)
    func remove(dataSource: DataSource)
    func removeAll()
}

public extension AggregateDataSource {

    var isEmpty: Bool {
        return activeChildren.lazy.allSatisfy { $0.isEmpty }
    }
    
}
