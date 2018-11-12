public protocol AggregateDataSource: DataSource {
    var children: [DataSource] { get }

//    func setDataSources(_ dataSources: [DataSource], changesets: [DataSourceChangeset])
    func insert(dataSource: DataSource, at index: Int)
    func remove(dataSource: DataSource)
    func removeAll()

}

public extension AggregateDataSource {

    var isEmpty: Bool {
        return children.allSatisfy { $0.isEmpty }
    }

    func setEditing(_ editing: Bool, animated: Bool) {
        children.forEach { $0.setEditing(editing, animated: animated) }
    }

    func didBecomeActive() {
        children.forEach { $0.didBecomeActive() }
    }

    func willResignActive() {
        children.forEach { $0.willResignActive() }
    }
    
}
