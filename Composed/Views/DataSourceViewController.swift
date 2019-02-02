import UIKit

open class DataSourceViewController: UIViewController {

    public var collectionView: UICollectionView {
        return wrapper.collectionView
    }

    public var dataSource: DataSource {
        return wrapper.dataSource
    }

    private let wrapper: CollectionViewWrapper
    public let layout: UICollectionViewLayout

    deinit {
        dataSource.willResignActive()
    }

    public init(dataSource: DataSource, layout: UICollectionViewLayout? = nil) {
        let layout = layout ?? FlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.wrapper = CollectionViewWrapper(collectionView: collectionView, dataSource: dataSource)
        self.layout = layout
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
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

        collectionView.dataSource = wrapper
        collectionView.delegate = wrapper
//        collectionView.prefetchDataSource = wrapper
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

    open func dataSource(_ dataSource: DataSource, willPerformOperations operations: [DataSourceUpdate]) { }
    open func dataSource(_ dataSource: DataSource, didPerformOperations operations: [DataSourceUpdate]) { }

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
