/// Provides a convenient wrapper around a dataSource to provide Hashable/Equatable support.
/// We don't want to add this support directly to DataSource since it would inhibit our
/// ability to store them in collections.
internal struct AnyDataSource: Hashable {

    let dataSource: DataSource

    init(_ dataSource: DataSource) {
        self.dataSource = dataSource
    }

    var hashValue: Int {
        return ObjectIdentifier(dataSource).hashValue
    }

    static func == (lhs: AnyDataSource, rhs: AnyDataSource) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

}
