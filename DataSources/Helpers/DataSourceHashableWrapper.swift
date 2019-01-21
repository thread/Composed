/// Provides a convenient wrapper around a dataSource to provide Hashable/Equatable support.
/// We don't want to add this support directly to DataSource since it would inhibit our
/// ability to store them in collections.
internal struct DataSourceHashableWrapper: Hashable {

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

}
