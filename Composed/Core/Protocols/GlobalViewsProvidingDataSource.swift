import Foundation

@available(*, deprecated, renamed: "GlobalProvidingDataSource")
public typealias DataSourceUIGlobalProviding = GlobalViewsProvidingDataSource

@available(*, deprecated, renamed: "GlobalViewsProvidingDataSource")
public typealias DataSourceUIGlobalProvider = GlobalViewsProvidingDataSource

public protocol GlobalViewsProvidingDataSource: DataSource {
    var placeholderView: UIView? { get }
    func globalHeaderConfiguration() -> DataSourceUIConfiguration?
    func globalFooterConfiguration() -> DataSourceUIConfiguration?
}

public extension GlobalViewsProvidingDataSource {
    var placeholderView: UIView? { return nil }
    func globalHeaderConfiguration() -> DataSourceUIConfiguration? { return nil }
    func globalFooterConfiguration() -> DataSourceUIConfiguration? { return nil }
}
