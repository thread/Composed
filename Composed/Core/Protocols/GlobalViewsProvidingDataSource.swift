import UIKit

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
