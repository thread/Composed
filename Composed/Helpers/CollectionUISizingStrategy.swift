import UIKit

@available(*, deprecated, renamed: "CollectionUISizingContext")
public typealias DataSourceUISizingContext = CollectionUISizingContext

public struct CollectionUISizingContext {
    public let prototype: UICollectionReusableView
    public let indexPath: IndexPath
    public let layoutSize: CGSize
    public let metrics: CollectionUISectionMetrics
}

@available(*, deprecated, renamed: "CollectionUISizingStrategy")
public typealias DataSourceUISizingStrategy = CollectionUISizingStrategy

public protocol CollectionUISizingStrategy {
    func cachedSize(forElementAt indexPath: IndexPath) -> CGSize?
    func size(forElementAt indexPath: IndexPath, context: CollectionUISizingContext, dataSource: DataSource) -> CGSize
}
