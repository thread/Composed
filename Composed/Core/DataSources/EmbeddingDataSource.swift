import UIKit

/**
 Use this DataSource to 'embed' another DataSource as a carousel for example.
 This DataSource will return a Carousel for each section in its child dataSource.
 Each section will then contain its own UICollectionView that will present the
 contents of the embedded DataSource
 */
open class EmbeddingDataSource: DataSource {

    internal let embedded: _EmbeddedDataSource

    public init(child: CollectionUIProvidingDataSource) {
        self.embedded = _EmbeddedDataSource(child: child)
        child.updateDelegate = embedded
    }

    public weak var updateDelegate: DataSourceUpdateDelegate?

    public var numberOfSections: Int {
        return embedded.numberOfSections
    }

    public func numberOfElements(in section: Int) -> Int {
        return 1
    }

    public func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath? {
        return embedded.indexPath(where: predicate)
    }

    public func localSection(for section: Int) -> (dataSource: DataSource, localSection: Int) {
        return (self, section)
    }

    public func dataSourceFor(global indexPath: IndexPath) -> (dataSource: DataSource, localIndexPath: IndexPath) {
        return (self, indexPath)
    }

}

extension EmbeddingDataSource: CollectionUIProvidingDataSource {

    public func metrics(for section: Int) -> CollectionUISectionMetrics {
        return .zero
    }

    public func sizingStrategy(in collectionView: UICollectionView) -> CollectionUISizingStrategy {
        return ColumnSizingStrategy(columnCount: 1, sizingMode: .automatic(isUniform: false))
    }

    public func cellConfiguration(for indexPath: IndexPath) -> CollectionUIViewProvider {
        return CollectionUIViewProvider(prototype: EmbeddedDataSourceCell.fromNib, dequeueMethod: .nib) { [unowned self] cell, _, _ in
            cell.prepare(dataSource: self.embedded)
        }
    }

    public func headerConfiguration(for section: Int) -> CollectionUIViewProvider? {
        return embedded.child.headerConfiguration(for: section)
    }

}

extension EmbeddingDataSource: DataSourceUpdateDelegate {

    public func dataSource(_ dataSource: DataSource, performUpdates changeDetails: ComposedChangeDetails) {
        fatalError("Implement")
    }

    public func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceInvalidationContext) {
        fatalError("Implement")
    }

    public func dataSource(_ dataSource: DataSource, sectionFor local: Int) -> (dataSource: DataSource, globalSection: Int) {
        return (self, local)
    }

}

internal class _EmbeddedDataSource: DataSource {

    public let child: CollectionUIProvidingDataSource
    weak var updateDelegate: DataSourceUpdateDelegate?

    public init(child: CollectionUIProvidingDataSource) {
        self.child = child
        child.updateDelegate = self
    }

    public var numberOfSections: Int {
        return 1
    }

    public func numberOfElements(in section: Int) -> Int {
        return child.numberOfElements(in: section)
    }

    public func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath? {
        return child.indexPath(where: predicate)
    }

    public func localSection(for section: Int) -> (dataSource: DataSource, localSection: Int) {
        return (child, 0)
    }

    public func dataSourceFor(global indexPath: IndexPath) -> (dataSource: DataSource, localIndexPath: IndexPath) {
        return (child, IndexPath(item: indexPath.item, section: 0))
    }

}

extension _EmbeddedDataSource: GlobalViewsProvidingDataSource {
    var placeholderView: UIView? {
        return (child as? GlobalViewsProvidingDataSource)?.placeholderView
    }
}

extension _EmbeddedDataSource: DataSourceUpdateDelegate {

    func dataSource(_ dataSource: DataSource, performUpdates changeDetails: ComposedChangeDetails) {
        updateDelegate?.dataSource(self, performUpdates: changeDetails)
    }

    public func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceInvalidationContext) {
        updateDelegate?.dataSource(self, invalidateWith: context)
    }

    public func dataSource(_ dataSource: DataSource, sectionFor local: Int) -> (dataSource: DataSource, globalSection: Int) {
        return (self, local)
    }

}
