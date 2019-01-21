public protocol AggregateDataSource: DataSource {
    var children: [DataSource] { get }

    func setDataSources(_ dataSources: [DataSource], changeset: DataSourceChangeset?)
    func insert(dataSource: DataSource, at index: Int)
    func remove(dataSource: DataSource)
    func removeAll()

}

public extension AggregateDataSource {

    var isEmpty: Bool {
        return children.lazy.allSatisfy { $0.isEmpty }
    }

    func didBecbomeActive() {
        children.forEach { $0.didBecomeActive() }
    }

    func willResignActive() {
        children.forEach { $0.willResignActive() }
    }
    
}
