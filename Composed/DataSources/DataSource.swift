// MARK: Changes to this delegate require careful consideration
// MARK: -
public protocol DataSourceUpdateDelegate: class {
    func dataSource(_ dataSource: DataSource, willPerform updates: [DataSourceUpdate])
    func dataSource(_ dataSource: DataSource, didPerform updates: [DataSourceUpdate])
    
    func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet)
    func dataSource(_ dataSource: DataSource, didDeleteSections sections: IndexSet)
    func dataSource(_ dataSource: DataSource, didUpdateSections sections: IndexSet)
    func dataSource(_ dataSource: DataSource, didMoveSection from: Int, to: Int)

    func dataSource(_ dataSource: DataSource, didInsertIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didDeleteIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didUpdateIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didMoveFromIndexPath from: IndexPath, toIndexPath to: IndexPath)

    func dataSourceDidReload(_ dataSource: DataSource)
    func dataSource(_ dataSource: DataSource, performBatchUpdates updates: () -> Void, completion: ((Bool) -> Void)?)
    func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceUIInvalidationContext)
}
// MARK: -

/// Represents a definition of a DataSource for representing a single source of data and its associated visual representations
public protocol DataSource: class {

    /// The delegate responsible for responding to update events. This is generally used for update propogation. The 'root' DataSource's delegate will generally be a `UIViewController`
    var updateDelegate: DataSourceUpdateDelegate? { get set }

    /// The number of sections this DataSource contains
    var numberOfSections: Int { get }

    /// The number of elements contained in the specified section
    ///
    /// - Parameter section: The section index
    /// - Returns: The number of elements contained in the specified section
    func numberOfElements(in section: Int) -> Int

    /// The indexPath of the element satisfying `predicate`. Returns nil if the predicate cannot be satisfied
    ///
    /// - Parameter predicate: The predicate to use
    /// - Returns: An `IndexPath` if the specified predicate can be satisfied, nil otherwise
    func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath?

    func dataSourceFor(global section: Int) -> (dataSource: DataSource, localSection: Int)
    func dataSourceFor(global indexPath: IndexPath) -> (dataSource: DataSource, localIndexPath: IndexPath)

}

public extension DataSource {

    var isEmpty: Bool {
        return (0..<numberOfSections)
            .lazy
            .allSatisfy { numberOfElements(in: $0) == 0 }
    }

}

public extension DataSource {

    public var isRoot: Bool {
        return !(updateDelegate is DataSource)
    }

    /// Returns true if the rootDataSource's updateDelegate is non-nil
    var isActive: Bool {
        var dataSource: DataSource = self

        while !dataSource.isRoot, let parent = dataSource.updateDelegate as? DataSource {
            dataSource = parent
        }

        return dataSource.updateDelegate != nil
    }

}

public protocol DataSourceLifecycleObserving {

    /// Called when the dataSource is initially prepared, or after an invalidation.
    func prepare()

    /// Called when the dataSource has been invalidated, generally when the dataSource has been removed
    func invalidate()

    /// Called whenever the dataSource becomes active, after being inactive
    func didBecomeActive()

    /// Called whenever the dataSource resigns active, after being active
    func willResignActive()

}

public protocol DataSourceSelecting: DataSource {
    func shouldSelectElement(at indexPath: IndexPath) -> Bool
    func shouldDeselectElement(at indexPath: IndexPath) -> Bool

    func selectElement(at indexPath: IndexPath)
    func deselectElement(at indexPath: IndexPath)
}

final class EmbeddedDataSourceCell: UICollectionViewCell {

    private static var scrollOffsets: [IndexPath: CGPoint] = [:]

    private var indexPath: IndexPath?

    private lazy var wrapper: CollectionViewWrapper = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        let wrapper = CollectionViewWrapper(collectionView: collectionView, dataSource: nil)

        contentView.backgroundColor = .clear
        contentView.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
        ])

        return wrapper
    }()

    func prepare(dataSource: CollectionViewDataSource) {
        wrapper.prepare(dataSource: dataSource)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let offset = type(of: self).scrollOffsets[layoutAttributes.indexPath] else { return }

        wrapper.collectionView.setContentOffset(offset, animated: false)
        indexPath = layoutAttributes.indexPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        guard let indexPath = indexPath else { return }

        _ = type(of: self).scrollOffsets[indexPath]
        type(of: self).scrollOffsets[indexPath] = wrapper.collectionView.contentOffset
    }

}

public final class EmbeddedContentDataSource<Element>: SectionedDataSource<Element>, DataSourceUIProviding where Element: CollectionViewDataSource {

    public let metrics: DataSourceUISectionMetrics
    private let dataSources: [Element]

    public init(dataSources: [Element], metrics: DataSourceUISectionMetrics) {
        self.dataSources = dataSources
        self.metrics = metrics
        super.init(elements: dataSources)
    }

    public func metrics(for section: Int) -> DataSourceUISectionMetrics {
        return metrics
    }

    public func sizingStrategy() -> DataSourceUISizingStrategy {
        return ColumnSizingStrategy(columnCount: 1, sizingMode: .automatic(isUniform: true))
    }

    public func cellConfiguration(for indexPath: IndexPath) -> DataSourceUIConfiguration {
        return DataSourceUIConfiguration(prototype: EmbeddedDataSourceCell(), dequeueSource: .class) { [unowned self] cell, indexPath in
            cell.prepare(dataSource: EmbeddedContentDataSource(dataSources: self.dataSources, metrics: self.metrics))
        }
    }

}
