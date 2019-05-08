/// Provides a convenient wrapper around a dataSource to provide Hashable/Equatable support.
/// We don't want to add this support directly to DataSource since it would inhibit our
/// ability to store them in collections.
internal struct DataSourceHashableWrapper: Hashable, CustomStringConvertible, CustomDebugStringConvertible {

    let dataSource: DataSource

    init(_ dataSource: DataSource) {
        self.dataSource = dataSource
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(dataSource))
    }

    static func == (lhs: DataSourceHashableWrapper, rhs: DataSourceHashableWrapper) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    var description: String {
        return _description(indent: 0, debug: false)
    }

    var debugDescription: String {
        return _description(indent: 0, debug: true)
    }

    internal func _description(indent level: Int, debug: Bool) -> String {
        let bullet = dataSource.isRoot ? "•" : "–"
        var summary = "\(String(repeating: " ", count: level))\(bullet) \(String(describing: type(of: dataSource)))"

        if debug {
            let count = dataSource.numberOfSections
            if count == 0 {
                summary += " | \(count) sections"
            } else {
                let lower = dataSource.updateDelegate?.dataSource(dataSource, sectionFor: 0).globalSection ?? 0
                let upper = dataSource.updateDelegate?.dataSource(dataSource, sectionFor: count - 1).globalSection ?? count
                summary += " | \(dataSource.numberOfSections) sections | \(lower...upper)"
            }
        }

        var description = [summary]

        if let aggregate = dataSource as? AggregateDataSource {
            let wrappers = aggregate.children.map { DataSourceHashableWrapper($0) }
            description += wrappers.map { $0._description(indent: level + 2, debug: debug) }
        }

        return description.joined(separator: "\n")
    }

}
