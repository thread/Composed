import UIKit

open class DataSourceViewController: UIViewController {

    open class var collectionViewClass: UICollectionView.Type {
        return UICollectionView.self
    }

    public var collectionView: UICollectionView {
        return wrapper.collectionView
    }

    public var dataSource: DataSource {
        return wrapper.dataSource
    }

    private let wrapper: CollectionViewWrapper
    public let layout: UICollectionViewLayout

    public init(dataSource: DataSource, layout: UICollectionViewLayout = FlowLayout()) {
        let collectionView = type(of: self).collectionViewClass.init(frame: .zero, collectionViewLayout: layout)
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

        wrapper.viewWillLoad()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard presentedViewController == nil else { return }
        wrapper.viewWillShow()
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        wrapper.viewWillHide()
    }

    open override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        wrapper.setEditing(editing, animated: animated)
    }

    open func dataSource(_ dataSource: DataSource, willPerform updates: [DataSourceUpdate]) { }
    open func dataSource(_ dataSource: DataSource, didPerform updates: [DataSourceUpdate]) { }

}

extension DataSourceViewController: DataSourceUpdateDelegate {

    ///    This is a little difficult to read and to see where the scopes exist.
    ///    But its highly efficient, so worthy of inclusion.
    ///
    ///    1. Grab all the local dataSources for each section inserted
    ///    2. Hash them to remove duplicates (since DS's can contain multiple sections)
    ///    3. Map them to DataSourceUILifecycleObserving
    ///    4. Call didBecomeActive
    private func lifecycleObservers(for sections: IndexSet, in dataSource: DataSource) -> [DataSourceUILifecycleObserving] {
        return Set(sections
            .lazy
            .map { dataSource.dataSourceFor(global: $0) }
            .map { DataSourceHashableWrapper($0.dataSource) })
            .lazy
            .compactMap { $0.dataSource as? DataSourceUILifecycleObserving }
    }

    public func dataSourceDidReload(_ dataSource: DataSource) {
        // Fetch the sections before the update
        let beforeSections = 0..<collectionView.numberOfSections

        // Update
        collectionView.reloadData()

        // Fetch the sections after the update
        let afterSections = 0..<collectionView.numberOfSections

        // Fetch the local DataSource's for each section before the update
        let before = Set(beforeSections
            .map { DataSourceHashableWrapper(dataSource.dataSourceFor(global: $0).dataSource) }
        )

        // Fetch the local DataSource's for each section after the update
        let after = Set(afterSections
            .map { DataSourceHashableWrapper(dataSource.dataSourceFor(global: $0).dataSource) }
        )

        let deleted = before.subtracting(after)
        let inserted = after.subtracting(before)

        // Call willResignActive on all deleted dataSource's
        deleted
            .lazy
            .compactMap { $0.dataSource as? DataSourceUILifecycleObserving }
            .forEach { $0.willResignActive() }

        // Call didBecomActive on all inserted dataSource's
        inserted
            .lazy
            .compactMap { $0.dataSource as? DataSourceUILifecycleObserving }
            .forEach { $0.didBecomeActive() }
    }

    public func dataSource(_ dataSource: DataSource, performBatchUpdates updates: () -> Void, completion: ((Bool) -> Void)?) {
        collectionView.performBatchUpdates(updates, completion: completion)
    }

    public func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet) {
        collectionView.insertSections(sections)
        lifecycleObservers(for: sections, in: dataSource).forEach { $0.didBecomeActive() }
    }

    public func dataSource(_ dataSource: DataSource, didDeleteSections sections: IndexSet) {
        collectionView.deleteSections(sections)
        lifecycleObservers(for: sections, in: dataSource).forEach { $0.willResignActive() }
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

    public func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceUIInvalidationContext) {
        wrapper.invalidate(with: context)
    }

}
