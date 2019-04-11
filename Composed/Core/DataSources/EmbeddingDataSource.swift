import UIKit

/**
 Use this DataSource to 'embed' another DataSource as a carousel for example.
 This DataSource will return a Carousel for each section in its child dataSource.
 Each section will then contain its own UICollectionView that will present the
 contents of the embedded DataSource
 */
open class EmbeddingDataSource: SearchableDataSource {

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

    public func indexPath<Element>(where predicate: @escaping (Element) -> Bool) -> IndexPath? {
        return (embedded.child as? SearchableDataSource)?.indexPath(where: predicate)
    }

    public func dataSourceFor(global section: Int) -> (dataSource: DataSource, localSection: Int) {
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

    public func cellConfiguration(for indexPath: IndexPath) -> DataSourceUIConfiguration {
        return DataSourceUIConfiguration(prototype: EmbeddedDataSourceCell.fromNib, dequeueSource: .nib) { [unowned self] cell, _, _ in
            cell.prepare(dataSource: self.embedded)
        }
    }

    public func headerConfiguration(for section: Int) -> DataSourceUIConfiguration? {
        return embedded.child.headerConfiguration(for: section)
    }

}

extension EmbeddingDataSource: DataSourceUpdateDelegate {

    public func dataSource(_ dataSource: DataSource, willPerform updates: [DataSourceUpdate]) {

    }

    public func dataSource(_ dataSource: DataSource, didPerform updates: [DataSourceUpdate]) {

    }

    public func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet) {
//        collectionView.insertSections(sections)
    }

    public func dataSource(_ dataSource: DataSource, didDeleteSections sections: IndexSet) {
//        collectionView.deleteSections(sections)
    }

    public func dataSource(_ dataSource: DataSource, didUpdateSections sections: IndexSet) {
//        collectionView.reloadSections(sections)
    }

    public func dataSource(_ dataSource: DataSource, didMoveSection from: Int, to: Int) {

    }

    public func dataSource(_ dataSource: DataSource, didInsertIndexPaths indexPaths: [IndexPath]) {

    }

    public func dataSource(_ dataSource: DataSource, didDeleteIndexPaths indexPaths: [IndexPath]) {

    }

    public func dataSource(_ dataSource: DataSource, didUpdateIndexPaths indexPaths: [IndexPath]) {

    }

    public func dataSource(_ dataSource: DataSource, didMoveFromIndexPath from: IndexPath, toIndexPath to: IndexPath) {

    }

    public func dataSourceDidReload(_ dataSource: DataSource) {

    }

    public func dataSource(_ dataSource: DataSource, performBatchUpdates updates: () -> Void, completion: ((Bool) -> Void)?) {

    }

    public func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceInvalidationContext) {

    }

    public func dataSource(_ dataSource: DataSource, globalFor local: IndexPath) -> (dataSource: DataSource, globalIndexPath: IndexPath) {
        return (self, local)
    }

    public func dataSource(_ dataSource: DataSource, globalFor local: Int) -> (dataSource: DataSource, globalSection: Int) {
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

    public func dataSourceFor(global section: Int) -> (dataSource: DataSource, localSection: Int) {
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

    public func dataSource(_ dataSource: DataSource, willPerform updates: [DataSourceUpdate]) {
        updateDelegate?.dataSource(self, willPerform: updates)
    }

    public func dataSource(_ dataSource: DataSource, didPerform updates: [DataSourceUpdate]) {
        updateDelegate?.dataSource(self, didPerform: updates)
    }

    public func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet) {
        updateDelegate?.dataSource(self, didInsertSections: sections)
    }

    public func dataSource(_ dataSource: DataSource, didDeleteSections sections: IndexSet) {
        updateDelegate?.dataSource(self, didDeleteSections: sections)
    }

    public func dataSource(_ dataSource: DataSource, didUpdateSections sections: IndexSet) {
        updateDelegate?.dataSource(self, didUpdateSections: sections)
    }

    public func dataSource(_ dataSource: DataSource, didMoveSection from: Int, to: Int) {
        updateDelegate?.dataSource(self, didMoveSection: from, to: to)
    }

    public func dataSource(_ dataSource: DataSource, didInsertIndexPaths indexPaths: [IndexPath]) {
        updateDelegate?.dataSource(self, didInsertIndexPaths: indexPaths)
    }

    public func dataSource(_ dataSource: DataSource, didDeleteIndexPaths indexPaths: [IndexPath]) {
        updateDelegate?.dataSource(self, didDeleteIndexPaths: indexPaths)
    }

    public func dataSource(_ dataSource: DataSource, didUpdateIndexPaths indexPaths: [IndexPath]) {
        updateDelegate?.dataSource(self, didUpdateIndexPaths: indexPaths)
    }

    public func dataSource(_ dataSource: DataSource, didMoveFromIndexPath from: IndexPath, toIndexPath to: IndexPath) {
        updateDelegate?.dataSource(self, didMoveFromIndexPath: from, toIndexPath: to)
    }

    public func dataSourceDidReload(_ dataSource: DataSource) {
        updateDelegate?.dataSourceDidReload(self)
    }

    public func dataSource(_ dataSource: DataSource, performBatchUpdates updates: () -> Void, completion: ((Bool) -> Void)?) {
        updateDelegate?.dataSource(self, performBatchUpdates: updates, completion: completion)
    }

    public func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceInvalidationContext) {
        updateDelegate?.dataSource(self, invalidateWith: context)
    }

    public func dataSource(_ dataSource: DataSource, globalFor local: IndexPath) -> (dataSource: DataSource, globalIndexPath: IndexPath) {
        return (self, local)
    }

    public func dataSource(_ dataSource: DataSource, globalFor local: Int) -> (dataSource: DataSource, globalSection: Int) {
        return (self, local)
    }

}
