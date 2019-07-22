import UIKit

public protocol GlobalViewsProvidingDataSource: DataSource {
    func globalHeaderConfiguration() -> CollectionUIViewProvider?
    func globalFooterConfiguration() -> CollectionUIViewProvider?
    func placeholderConfiguration() -> CollectionUIViewProvider?
}

public extension GlobalViewsProvidingDataSource {
    func globalHeaderConfiguration() -> CollectionUIViewProvider? { return nil }
    func globalFooterConfiguration() -> CollectionUIViewProvider? { return nil }
    func placeholderConfiguration() -> CollectionUIViewProvider? { return nil }
}
