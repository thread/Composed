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
    func backgroundViewClass(for section: Int) -> UICollectionReusableView.Type?
}

public extension CollectionUIProvidingDataSource {
    func headerConfiguration(for section: Int) -> CollectionUIViewProvider? { return nil }
    func footerConfiguration(for section: Int) -> CollectionUIViewProvider? { return nil }
    func backgroundViewClass(for section: Int) -> UICollectionReusableView.Type? { return nil }

    func willBeginDisplay(ofCell cell: UICollectionViewCell, at indexPath: IndexPath) { }
    func didEndDisplay(ofCell cell: UICollectionViewCell, at indexPath: IndexPath) { }

    func willBeginDisplay() { }
    func didEndDisplay() { }
}

extension DataSource where Self: CollectionUIProvidingDataSource {

    public var indexPathsForVisibleElements: [IndexPath] {
        return []
    }

    public var indexPathsForSelectedElements: [IndexPath] {
        return []
    }

    public func resuableView(for indexPath: IndexPath, of kind: String? = nil) -> UICollectionReusableView? {
        return nil
    }

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
