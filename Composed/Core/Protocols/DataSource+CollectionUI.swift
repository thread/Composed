import UIKit

public struct CollectionUISectionMetrics {

    public let insets: UIEdgeInsets
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat

    public init(insets: UIEdgeInsets, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        self.insets = insets
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

}

@available(*, deprecated, renamed: "CollectionUIProvidingDataSource")
public typealias DataSourceUIProviding = CollectionUIProvidingDataSource

public protocol CollectionUIProvidingDataSource: DataSource {
    func sizingStrategy() -> CollectionUISizingStrategy
    func metrics(for section: Int) -> CollectionUISectionMetrics
    func cellConfiguration(for indexPath: IndexPath) -> DataSourceUIConfiguration
    func headerConfiguration(for section: Int) -> DataSourceUIConfiguration?
    func footerConfiguration(for section: Int) -> DataSourceUIConfiguration?
    func backgroundViewClass(for section: Int) -> UICollectionReusableView.Type?

    func willBeginDisplay()
    func didEndDisplay()
}

public extension CollectionUIProvidingDataSource {
    func headerConfiguration(for section: Int) -> DataSourceUIConfiguration? { return nil }
    func footerConfiguration(for section: Int) -> DataSourceUIConfiguration? { return nil }
    func backgroundViewClass(for section: Int) -> UICollectionReusableView.Type? { return nil }

    func willBeginDisplay() { }
    func didEndDisplay() { }
}

extension DataSource where Self: CollectionUIProvidingDataSource {

    public var collectionView: UICollectionView? {
        if let wrapper = updateDelegate as? CollectionViewWrapper {
            return wrapper.collectionView
        }

        var parent: DataSource? = self

        while let p = parent, !p.isRoot {
            parent = p.updateDelegate as? DataSource
        }

        if let wrapper = parent?.updateDelegate as? CollectionViewWrapper {
            return wrapper.collectionView
        }

        return nil
    }

}
