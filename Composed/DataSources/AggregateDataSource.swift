public protocol AggregateDataSource: DataSource {
    var children: [DataSource] { get }

    func insert(dataSource: DataSource, at index: Int)
    func remove(dataSource: DataSource)
    func removeAll()

}

public extension AggregateDataSource {

    var isEmpty: Bool {
        return children.lazy.allSatisfy { $0.isEmpty }
    }

    func didBecomeActive() {
        children.forEach { $0.didBecomeActive() }
    }

    func willResignActive() {
        children.forEach { $0.willResignActive() }
    }
    
}

public extension DataSource {

    var ancestors: [DataSource] {
        var parent = updateDelegate as? DataSource
        var dataSources: [DataSource] = []

        while let dataSource = parent {
            dataSources.append(dataSource)
            parent = dataSource.updateDelegate as? DataSource
        }

        return dataSources
    }

    var siblings: [DataSource] {
        guard let parent = updateDelegate as? AggregateDataSource else { return [] }
        return parent.children.filter { $0 !== self }
    }

    var descendants: [DataSource] {
        return _descendants.filter { $0 !== self }
    }

    private var _descendants: [DataSource] {
        if let aggregate = self as? AggregateDataSource {
            return [self] + aggregate.children.flatMap { $0._descendants }
        } else {
            return [self]
        }
    }

}
