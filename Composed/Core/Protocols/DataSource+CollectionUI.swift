import UIKit

@available(*, deprecated, renamed: "CollectionUISectionMetrics")
public typealias DataSourceUISectionMetrics = CollectionUISectionMetrics

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

@available(*, deprecated, renamed: "CollectionUIProvidingDataSource")
public typealias DataSourceUIProviding = CollectionUIProvidingDataSource

public protocol CollectionUIProvidingDataSource: DataSource {
    func sizingStrategy(in collectionView: UICollectionView) -> CollectionUISizingStrategy
    func metrics(for section: Int) -> CollectionUISectionMetrics
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

public protocol DataSourceMenuHandlingCell: UICollectionViewCell {
    func handle(action: Selector)
}

public extension DataSourceMenuHandlingCell {
    func handle(action: Selector) {
        guard let view = superview as? UICollectionView else { fatalError() }
        view.delegate?.collectionView?(view, performAction: action, forItemAt: view.indexPath(for: self)!, withSender: self)
    }
}

public protocol MenuProvidingDataSource {
    func menuItems(for indexPath: IndexPath) -> [UIMenuItem]
    func perform(action: Selector, for indexPath: IndexPath)
}
