public protocol GlobalProvidingDataSource: DataSource {
    var placeholderView: UIView? { get }
    func globalHeaderConfiguration() -> DataSourceUIConfiguration?
    func globalFooterConfiguration() -> DataSourceUIConfiguration?
}

public extension GlobalProvidingDataSource {
    var placeholderView: UIView? { return nil }
    func globalHeaderConfiguration() -> DataSourceUIConfiguration? { return nil }
    func globalFooterConfiguration() -> DataSourceUIConfiguration? { return nil }
}
