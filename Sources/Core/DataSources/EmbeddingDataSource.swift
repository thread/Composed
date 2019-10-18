import UIKit

/**
 Use this DataSource to 'embed' another DataSource as a carousel for example.
 This DataSource will return a Carousel for each section in its child dataSource.
 Each section will then contain its own UICollectionView that will present the
 contents of the embedded DataSource
 */
open class EmbeddingDataSource: DataSource {
    
    public let sizeMode: CarouselSizingStrategy.SizingMode

    fileprivate let embedded: _EmbeddedDataSource
    
    private var contentOffset: CGPoint = .zero
    private var selectedIndexPaths: [IndexPath] = []
    private let sectionMetrics: CollectionUISectionMetrics

    public init(child: CollectionUIProvidingDataSource, sizeMode: CarouselSizingStrategy.SizingMode, sectionMetrics: CollectionUISectionMetrics = .zero) {
        self.embedded = _EmbeddedDataSource(child: child, sizeMode: sizeMode)
        child.updateDelegate = embedded
        self.sectionMetrics = sectionMetrics
        self.sizeMode = sizeMode
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
    
    public var descendants: [DataSource] {
        return embedded.descendants
    }

}

extension EmbeddingDataSource: CollectionUIProvidingDataSource {

    public func metrics(for section: Int, traitCollection: UITraitCollection, layoutSize: CGSize) -> CollectionUISectionMetrics {
        return sectionMetrics
    }

    public func sizingStrategy(for traitCollection: UITraitCollection, layoutSize: CGSize) -> CollectionUISizingStrategy {
        return EmbeddingSizingStrategy(embeddedDataSource: embedded)
    }

    public func cellConfiguration(for indexPath: IndexPath) -> CollectionUIViewProvider {
        return CollectionUIViewProvider(prototype: EmbeddedDataSourceCell(frame: .zero), dequeueMethod: .class) { [weak self] cell, _, _ in
            guard let self = self else {
                assertionFailure("Configuration should be not be alive when data source has been deallocated")
                return
            }
            
            cell.prepare(dataSource: self.embedded, contentOffset: self.contentOffset, selectedIndexPaths: self.selectedIndexPaths)
            cell.delegate = self
        }
    }

    public func headerConfiguration(for section: Int) -> CollectionUIViewProvider? {
        return embedded.child.headerConfiguration(for: section)
    }

    public func footerConfiguration(for section: Int) -> CollectionUIViewProvider? {
        return embedded.child.footerConfiguration(for: section)
    }
    
    public func backgroundConfiguration(for section: Int) -> CollectionUIBackgroundProvider? {
        return embedded.child.backgroundConfiguration(for: section)
    }

}

extension EmbeddingDataSource: EmbeddedDataSourceCellDelegate {
    
    func embeddedCell(_ cell: EmbeddedDataSourceCell, cacheValuesFor contentOffset: CGPoint, selectedIndexPaths: [IndexPath]) {
        self.contentOffset = contentOffset
        self.selectedIndexPaths = selectedIndexPaths
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
    public let sizeMode: CarouselSizingStrategy.SizingMode
    weak var updateDelegate: DataSourceUpdateDelegate?
    
    public var descendants: [DataSource] {
        return [child]
    }

    public init(child: CollectionUIProvidingDataSource, sizeMode: CarouselSizingStrategy.SizingMode) {
        self.child = child
        self.sizeMode = sizeMode
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
        return (self, 0)
    }

    public func dataSourceFor(global indexPath: IndexPath) -> (dataSource: DataSource, localIndexPath: IndexPath) {
        return (self, IndexPath(item: indexPath.item, section: 0))
    }

}

extension _EmbeddedDataSource: CollectionUIProvidingDataSource {

    public func metrics(for section: Int, traitCollection: UITraitCollection, layoutSize: CGSize) -> CollectionUISectionMetrics {
        return child.metrics(for: section, traitCollection: traitCollection, layoutSize: layoutSize)
    }
    
    public func cellConfiguration(for indexPath: IndexPath) -> CollectionUIViewProvider {
        return child.cellConfiguration(for: indexPath)
    }

    public func sizingStrategy(for traitCollection: UITraitCollection, layoutSize: CGSize) -> CollectionUISizingStrategy {
        return CarouselSizingStrategy(sizingMode: sizeMode)
    }
    
    public func headerConfiguration(for section: Int) -> CollectionUIViewProvider? {
        return nil
    }
    
    public func footerConfiguration(for section: Int) -> CollectionUIViewProvider? {
        return nil
    }
    
    public func backgroundConfiguration(for section: Int) -> CollectionUIBackgroundProvider? {
        return nil
    }
    
}

extension _EmbeddedDataSource: SelectionHandlingDataSource {
    
    public var allowsMultipleSelection: Bool {
        return (child as? SelectionHandlingDataSource)?.allowsMultipleSelection ?? false
    }
    
    public func selectionHandler(forElementAt indexPath: IndexPath) -> (() -> Void)? {
        return (child as? SelectionHandlingDataSource)?.selectionHandler(forElementAt: indexPath)
    }
    
    public func deselectionHandler(forElementAt indexPath: IndexPath) -> (() -> Void)? {
        return (child as? SelectionHandlingDataSource)?.deselectionHandler(forElementAt: indexPath)
    }
    
    var selectedIndexPaths: [IndexPath] {
        return (child as? SelectionHandlingDataSource)?.selectedIndexPaths ?? []
    }

}

extension _EmbeddedDataSource: EditHandlingDataSource {
    
    public func supportsEditing(for indexPath: IndexPath) -> Bool {
        return (child as? EditHandlingDataSource)?.supportsEditing(for: indexPath) ?? false
    }
    
    public func setEditing(_ editing: Bool, animated: Bool) {
        (child as? EditHandlingDataSource)?.setEditing(editing, animated: animated)
    }
    
    public var isEditing: Bool {
        return (child as? EditHandlingDataSource)?.isEditing ?? false
    }
    
}

extension _EmbeddedDataSource: GlobalViewsProvidingDataSource {
    func placeholderConfiguration() -> CollectionUIViewProvider? {
        return (child as? GlobalViewsProvidingDataSource)?.placeholderConfiguration()
    }
}

extension _EmbeddedDataSource: DataSourceUpdateDelegate {

    public func dataSource(_ dataSource: DataSource, performUpdates changeDetails: ComposedChangeDetails) {
        updateDelegate?.dataSource(self, performUpdates: changeDetails)
    }

    public func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceInvalidationContext) {
        updateDelegate?.dataSource(self, invalidateWith: context)
    }

    public func dataSource(_ dataSource: DataSource, sectionFor local: Int) -> (dataSource: DataSource, globalSection: Int) {
        return (self, local)
    }

}

public extension DataSource {
    
    var isEmbedded: Bool {
        guard let delegate = updateDelegate else { return false }
        return delegate is _EmbeddedDataSource
    }

}

/**
 A sizing strategy that is capable of sizing a cell that will contain
 an embedded data source
 */
private class EmbeddingSizingStrategy: CollectionUISizingStrategy {
    
    private let embeddedDataSource: _EmbeddedDataSource
    
    private var cachedSize: CGSize?
    
    internal init(embeddedDataSource: _EmbeddedDataSource) {
        self.embeddedDataSource = embeddedDataSource
    }
    
    public func cachedSize(forElementAt indexPath: IndexPath) -> CGSize? {
        return cachedSize
    }
    
    open func size(forElementAt indexPath: IndexPath, context: CollectionUISizingContext, dataSource: DataSource) -> CGSize {
        if let size = cachedSize { return size }
        
        let height: CGFloat
        
        switch embeddedDataSource.sizeMode {
        case let .fixedHeight(fixedHeight):
            height = fixedHeight
        case let .fixedSize(size):
            height = size.height
        case .fixedWidth:
            guard let cell = context.prototype as? EmbeddedDataSourceCell else {
                return .zero
            }

            height = largestSizeOfChild(in: cell).height
        case let .automatic(isUniform):
            guard let cell = context.prototype as? EmbeddedDataSourceCell else {
                return .zero
            }
            
            if isUniform {
                height = cell.wrapper.collectionView(cell.collectionView, layout: cell.collectionView.collectionViewLayout, sizeForItemAt: indexPath).height
            } else {
                height = largestSizeOfChild(in: cell).height
            }
        }
        
        let metrics = embeddedDataSource.metrics(for: 0, traitCollection: context.traitCollection, layoutSize: context.layoutSize)
        let metricExtras = metrics.insets.top + metrics.insets.bottom
        let size = CGSize(width: context.layoutSize.width, height: height + metricExtras)
        cachedSize = size
        return size
    }
    
    private func largestSizeOfChild(in cell: EmbeddedDataSourceCell) -> CGSize {
        let indexPaths = (0..<embeddedDataSource.numberOfElements(in: 0)).map { IndexPath(item: $0, section: 0) }
        return indexPaths.reduce(into: CGSize.zero, { largestSize, indexPath in
            let size = cell.wrapper.collectionView(cell.collectionView, layout: cell.collectionView.collectionViewLayout, sizeForItemAt: indexPath)
            if size.height > largestSize.height {
                largestSize = size
            }
        })
    }
    
}
