import UIKit

public struct CollectionUISizingContext {
    public let prototype: UICollectionReusableView
    public let indexPath: IndexPath
    public let layoutSize: CGSize
    public let metrics: CollectionUISectionMetrics
    public let traitCollection: UITraitCollection
}

public protocol CollectionUISizingStrategy {
    func cachedSize(forElementAt indexPath: IndexPath) -> CGSize?
    func size(forElementAt indexPath: IndexPath, context: CollectionUISizingContext, dataSource: DataSource) -> CGSize
}
