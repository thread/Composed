public protocol DataSourceUIGlobalProvider {
    func globalHeaderConfiguration() -> DataSourceUIConfiguration?
    func globalFooterConfiguration() -> DataSourceUIConfiguration?
}

public extension DataSourceUIGlobalProvider {
    func globalHeaderConfiguration() -> DataSourceUIConfiguration? { return nil }
    func globalFooterConfiguration() -> DataSourceUIConfiguration? { return nil }
}
