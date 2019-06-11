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

    public static let zero = CollectionUISectionMetrics(insets: .zero, horizontalSpacing: 0, verticalSpacing: 0)

}

public protocol CollectionUIProvidingDataSource: DataSource {
    func sizingStrategy(for traitCollection: UITraitCollection, layoutSize: CGSize) -> CollectionUISizingStrategy
    func metrics(for section: Int, traitCollection: UITraitCollection, layoutSize: CGSize) -> CollectionUISectionMetrics
    func cellConfiguration(for indexPath: IndexPath) -> CollectionUIViewProvider
    func headerConfiguration(for section: Int) -> CollectionUIViewProvider?
    func footerConfiguration(for section: Int) -> CollectionUIViewProvider?
    func backgroundConfiguration(for section: Int) -> CollectionUIViewProvider?
}

public extension CollectionUIProvidingDataSource {
    func headerConfiguration(for section: Int) -> CollectionUIViewProvider? { return nil }
    func footerConfiguration(for section: Int) -> CollectionUIViewProvider? { return nil }
    func backgroundConfiguration(for section: Int) -> CollectionUIViewProvider? { return nil }
}

extension DataSource where Self: CollectionUIProvidingDataSource {

    internal var collectionView: UICollectionView? {
        if let wrapper = updateDelegate as? DataSourceCoordinator {
            return wrapper.collectionView
        }

        var parent: DataSource? = self

        while let p = parent, !p.isRoot {
            parent = p.updateDelegate as? DataSource
        }

        if let wrapper = parent?.updateDelegate as? DataSourceCoordinator {
            return wrapper.collectionView
        }

        return nil
    }

}
