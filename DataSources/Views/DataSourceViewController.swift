import UIKit

open class DataSourceViewController: UIViewController {

    public let collectionView: UICollectionView
    public let dataSource: DataSource
    public let layout: UICollectionViewLayout

    deinit {
        dataSource.willResignActive()
    }

    public init(dataSource: DataSource, layout: UICollectionViewLayout? = nil) {
        self.dataSource = dataSource
        self.layout = layout ?? FlowLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)

        super.init(nibName: nil, bundle: nil)

        self.navigationItem.title = dataSource.title
        self.tabBarItem.title = dataSource.title
        self.tabBarItem.image = dataSource.image
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    open override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        dataSource.setEditing(editing, animated: animated)

        collectionView
            .visibleCells
            .lazy
            .compactMap { $0 as? DataSourceCell }
            .forEach {
                $0.setEditing(editing, animated: animated)
        }

        collectionView
            .visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)
            .lazy
            .compactMap { $0 as? DataSourceHeaderView }
            .forEach {
                $0.setEditing(editing, animated: animated)
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = .top
        extendedLayoutIncludesOpaqueBars = true

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            view.topAnchor.constraint(equalTo: collectionView.topAnchor),
            view.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
        ])

        dataSource.updateDelegate = self
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true

//        dataSource.registerReusableViews(inCollectionView: collectionView)
//        collectionView.dataSource = dataSource
//        collectionView.delegate = dataSource
//        collectionView.prefetchDataSource = dataSource
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard presentedViewController == nil else { return }
        dataSource.didBecomeActive()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.flashScrollIndicators()
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dataSource.willResignActive()
    }

    open func dataSource<T>(_ dataSource: DataSource, changesetFor sourceItems: [T], targetItems: [T]) -> [DataSourceChangeset]? where T: Equatable {
        return nil
    }

    open func dataSource(_ dataSource: DataSource, didSelectModel model: Any, atIndexPath: IndexPath) { }
    open func dataSource(_ dataSource: DataSource, didDeselectModel model: Any, atIndexPath: IndexPath) { }

    open func dataSource(_ dataSource: DataSource, willPerformOperations operations: [DataSourceUpdate]) { }
    open func dataSource(_ dataSource: DataSource, didPerformOperations operations: [DataSourceUpdate]) { }
    open func dataSource(_ dataSource: DataSource, didScrollToContentOffset contentOffset: CGPoint) { }

}

extension DataSourceViewController: DataSourceUpdateDelegate {

    open func dataSource(_ dataSource: DataSource, willPerform updates: [DataSourceUpdate]) { }
    open func dataSource(_ dataSource: DataSource, didPerform updates: [DataSourceUpdate]) { }

    public func dataSourceDidReload(_ dataSource: DataSource) {
        collectionView.reloadData()
    }

    public func dataSource(_ dataSource: DataSource, performBatchUpdates updates: () -> Void, completion: ((Bool) -> Void)?) {
        collectionView.performBatchUpdates(updates, completion: completion)
    }

    public func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet) {
        collectionView.insertSections(sections)
    }

    public func dataSource(_ dataSource: DataSource, didDeleteSections sections: IndexSet) {
        collectionView.deleteSections(sections)
    }

    public func dataSource(_ dataSource: DataSource, didUpdateSections sections: IndexSet) {
        collectionView.reloadSections(sections)
    }

    public func dataSource(_ dataSource: DataSource, didMoveSection from: Int, to: Int) {
        collectionView.moveSection(from, toSection: to)
    }

    public func dataSource(_ dataSource: DataSource, didInsertIndexPaths indexPaths: [IndexPath]) {
        collectionView.insertItems(at: indexPaths)
    }

    public func dataSource(_ dataSource: DataSource, didDeleteIndexPaths indexPaths: [IndexPath]) {
        collectionView.deleteItems(at: indexPaths)
    }

    public func dataSource(_ dataSource: DataSource, didUpdateIndexPaths indexPaths: [IndexPath]) {
        collectionView.reloadItems(at: indexPaths)
    }

    public func dataSource(_ dataSource: DataSource, didMoveFromIndexPath from: IndexPath, toIndexPath to: IndexPath) {
        collectionView.moveItem(at: from, to: to)
    }

}
