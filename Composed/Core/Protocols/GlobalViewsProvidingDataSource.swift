import UIKit

@available(*, deprecated, renamed: "GlobalProvidingDataSource")
public typealias DataSourceUIGlobalProviding = GlobalViewsProvidingDataSource

@available(*, deprecated, renamed: "GlobalViewsProvidingDataSource")
public typealias DataSourceUIGlobalProvider = GlobalViewsProvidingDataSource

public protocol GlobalViewsProvidingDataSource: DataSource {
    var placeholderView: UIView? { get }
    func globalHeaderConfiguration() -> CollectionUIViewProvider?
    func globalFooterConfiguration() -> CollectionUIViewProvider?
}

public extension GlobalViewsProvidingDataSource {
    var placeholderView: UIView? { return nil }
    func globalHeaderConfiguration() -> CollectionUIViewProvider? { return nil }
    func globalFooterConfiguration() -> CollectionUIViewProvider? { return nil }
}
