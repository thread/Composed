import UIKit

public typealias CollectionViewDataSource = DataSource & CollectionUIProvidingDataSource

internal final class CollectionViewWrapper: NSObject, UICollectionViewDataSource, FlowLayoutDelegate {

    internal let collectionView: UICollectionView

    #warning("Make this optional and update code throughout to deal with that")
    private(set) var dataSource: DataSource! {
        willSet {
            resignActive()

            if newValue !== dataSource, let ds = dataSource as? LifecycleObservingDataSource {
                ds.willResignActive()
                ds.invalidate()
            }
        }
        didSet {
            if let ds = dataSource as? LifecycleObservingDataSource {
                ds.prepare()

                if collectionView.window != nil {
                    ds.didBecomeActive()
                }
            }

            dataSource?.updateDelegate = self
            collectionView.delegate = self
            collectionView.dataSource = self
        }
    }

    private var globalConfigurations: [String: DataSourceUIConfiguration] = [:]
    private var headerConfigurations: [Int: DataSourceUIConfiguration] = [:]
    private var footerConfigurations: [Int: DataSourceUIConfiguration] = [:]
    private var cellConfigurations: [IndexPath: DataSourceUIConfiguration] = [:]
    private var metrics: [Int: CollectionUISectionMetrics] = [:]
    private var sizingStrategies: [Int: CollectionUISizingStrategy] = [:]

    private var isEditing: Bool = false

    internal init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
    }

    internal func replace(dataSource: DataSource) {
        self.dataSource = dataSource
    }

    @objc internal func becomeActive() {
        collectionView.flashScrollIndicators()
        preparePlaceholderIfNeeded()
    }

    @objc internal func resignActive() {
        
    }

    @objc internal func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSections
    }

    @objc public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfElements(in: section)
    }

    internal func setEditing(_ editing: Bool, animated: Bool) {
        isEditing = editing

        let globalHeader = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalHeader, at: UICollectionView.globalElementIndexPath)
        let globalFooter = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalFooter, at: UICollectionView.globalElementIndexPath)
        let headers = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)
        let footers = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter)

        [[globalHeader, globalFooter]
            .lazy
            .compactMap { $0 }, headers, footers]
            .flatMap { $0 }
            .compactMap { $0 as? DataSourceEditableView }
            .forEach { $0.setEditing(editing, animated: animated) }

        let itemIndexPaths = collectionView.indexPathsForVisibleItems

        for global in itemIndexPaths {
            let (localDataSource, local) = dataSource.dataSourceFor(global: global)

            guard let dataSource = localDataSource as? EditHandlingDataSource,
                dataSource.supportsEditing(for: local) else { continue }

            dataSource.setEditing(editing, animated: animated)

            let cell = collectionView.cellForItem(at: global) as? DataSourceEditableView
            cell?.setEditing(editing, animated: animated)
        }
    }

    internal func invalidate(with context: DataSourceInvalidationContext) {
        defer {
            if context.invalidateGlobalHeaderData, let view = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalHeader, at: UICollectionView.globalElementIndexPath) {
                self.collectionView(collectionView, willDisplaySupplementaryView: view, forElementKind: UICollectionView.elementKindGlobalHeader, at: UICollectionView.globalElementIndexPath)
            }

            if context.invalidateGlobalFooterData, let view = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalFooter, at: UICollectionView.globalElementIndexPath) {
                self.collectionView(collectionView, willDisplaySupplementaryView: view, forElementKind: UICollectionView.elementKindGlobalFooter, at: UICollectionView.globalElementIndexPath)
            }
        }

        let layoutContext = FlowLayoutInvalidationContext()
        layoutContext.invalidateItems(at: Array(context.invalidatedElementIndexPaths))
        layoutContext.invalidateFlowLayoutDelegateMetrics = context.invalidateLayoutMetrics

        let headerIndexPaths = context.invalidatedHeaderIndexes.map { IndexPath(item: 0, section: $0) }
        if !headerIndexPaths.isEmpty {
            layoutContext.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader, at: headerIndexPaths)
        }

        let footerIndexPaths = context.invalidatedFooterIndexes.map { IndexPath(item: 0, section: $0) }
        if !footerIndexPaths.isEmpty {
            layoutContext.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionFooter, at: footerIndexPaths)
        }

        layoutContext.invalidateGlobalHeader = context.invalidateGlobalHeaderMetrics
        layoutContext.invalidateGlobalFooter = context.invalidateGlobalFooterMetrics

        if context.invalidateLayoutMetrics {
            sizingStrategies.removeAll()
            metrics.removeAll()
        }

        collectionView.collectionViewLayout.invalidateLayout(with: layoutContext)
    }

    internal func dataSource(_ dataSource: DataSource, willPerform updates: [DataSourceUpdate]) { }
    internal func dataSource(_ dataSource: DataSource, didPerform updates: [DataSourceUpdate]) {
        preparePlaceholderIfNeeded()
    }

    private func preparePlaceholderIfNeeded() {
        collectionView.backgroundView = dataSource.isEmpty
            ? (dataSource as? GlobalViewsProvidingDataSource)?.placeholderView
            : nil
    }

}

extension CollectionViewWrapper {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let (localDataSource, localSection) = localDataSourceAndSection(for: section)
        return metrics(for: localSection, globalSection: section, in: localDataSource).insets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let (localDataSource, localSection) = localDataSourceAndSection(for: section)
        return metrics(for: localSection, globalSection: section, in: localDataSource).horizontalSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let (localDataSource, localSection) = localDataSourceAndSection(for: section)
        return metrics(for: localSection, globalSection: section, in: localDataSource).verticalSpacing
    }

}

extension CollectionViewWrapper {

    func backgroundViewClass(in collectionView: UICollectionView, forSectionAt section: Int) -> UICollectionReusableView.Type? {
        let (localDataSource, localSection) = localDataSourceAndSection(for: section)
        return localDataSource.backgroundViewClass(for: localSection)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // todo: this is a little informal but we can rely on the fact that sections will be queried first and only when the whole section was invalidated. Therefore its safe to say we should purge any caches we hold onto based on sections and lazily re-query them at a later time.
        sizingStrategies[section] = nil
        metrics[section] = nil

        let (localDataSource, localSection) = localDataSourceAndSection(for: section)

        guard let config = localDataSource.headerConfiguration(for: localSection) else {
            headerConfigurations[section] = nil
            return .zero
        }

        headerConfigurations[section] = config

        let width = collectionView.bounds.width
        let target = CGSize(width: width, height: 0)

        config.configure(config.prototype, IndexPath(item: 0, section: localSection), .sizing)
        return config.prototype.systemLayoutSizeFitting(
            target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let (localDataSource, localSection) = localDataSourceAndSection(for: section)

        guard let config = localDataSource.footerConfiguration(for: localSection) else {
            footerConfigurations[section] = nil
            return .zero
        }

        footerConfigurations[section] = config

        let width = collectionView.bounds.width
        let target = CGSize(width: width, height: 0)

        config.configure(config.prototype, IndexPath(item: 0, section: localSection), .sizing)
        return config.prototype.systemLayoutSizeFitting(
            target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let configuration: DataSourceUIConfiguration?

        switch (kind, dataSource) {
        case let (UICollectionView.elementKindGlobalHeader, dataSource as GlobalViewsProvidingDataSource):
            configuration = globalConfigurations[kind]
                ?? dataSource.globalHeaderConfiguration()

        case let (UICollectionView.elementKindGlobalFooter, dataSource as GlobalViewsProvidingDataSource):
            configuration = globalConfigurations[kind]
                ?? dataSource.globalFooterConfiguration()

        case (UICollectionView.elementKindSectionHeader, _):
            let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)
            configuration = headerConfigurations[indexPath.section]
                ?? localDataSource.headerConfiguration(for: localIndexPath.section)

        case (UICollectionView.elementKindSectionFooter, _):
            let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)
            configuration = footerConfigurations[indexPath.section]
                ?? localDataSource.footerConfiguration(for: localIndexPath.section)

        default:
            fatalError("Unsupported supplementary view. Only global and section header/footer views are supported.")
        }

        guard let config = configuration else {
            fatalError("Supported kind: \(kind) did not return a view for indexPath: \(indexPath)")
        }

        let type = Swift.type(of: config.prototype)
        switch config.dequeueSource {
        case .nib:
            collectionView.register(nibType: type, reuseIdentifier: config.reuseIdentifier, kind: kind)
        case .class:
            collectionView.register(classType: type, reuseIdentifier: config.reuseIdentifier, kind: kind)
        }

        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: config.reuseIdentifier, for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        let configuration: DataSourceUIConfiguration?

        switch (elementKind, dataSource) {
        case let (UICollectionView.elementKindGlobalHeader, dataSource as GlobalViewsProvidingDataSource):
            configuration = globalConfigurations[elementKind]
                ?? dataSource.globalHeaderConfiguration()

        case let (UICollectionView.elementKindGlobalFooter, dataSource as GlobalViewsProvidingDataSource):
            configuration = globalConfigurations[elementKind]
                ?? dataSource.globalFooterConfiguration()

        case (UICollectionView.elementKindSectionHeader, _):
            let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)
            configuration = headerConfigurations[indexPath.section]
                ?? localDataSource.headerConfiguration(for: localIndexPath.section)

        case (UICollectionView.elementKindSectionFooter, _):
            let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)
            configuration = footerConfigurations[indexPath.section]
                ?? localDataSource.footerConfiguration(for: localIndexPath.section)

        default:
            return
        }

        defer {
            configuration?.configure(view, indexPath, .presentation)
        }

        let (localDataSource, _) = indexPath == UICollectionView.globalElementIndexPath
            ? (dataSource!, indexPath)
            : dataSource.dataSourceFor(global: indexPath)

        guard let editable = localDataSource as? EditHandlingDataSource else { return }
        (view as? DataSourceEditableView)?.setEditing(editable.isEditing, animated: false)
    }

}

extension CollectionViewWrapper {

    func heightForGlobalHeader(in collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout) -> CGFloat {
        guard let config = (dataSource as? GlobalViewsProvidingDataSource)?.globalHeaderConfiguration() else {
            globalConfigurations[UICollectionView.elementKindGlobalHeader] = nil
            return 0
        }

        globalConfigurations[UICollectionView.elementKindGlobalHeader] = config

        let width = collectionView.bounds.width
        let target = CGSize(width: width, height: 0)

        config.configure(config.prototype, UICollectionView.globalElementIndexPath, .sizing)
        return config.prototype.systemLayoutSizeFitting(
            target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel).height
    }

    func heightForGlobalFooter(in collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout) -> CGFloat {
        guard let config = (dataSource as? GlobalViewsProvidingDataSource)?.globalFooterConfiguration() else {
            globalConfigurations[UICollectionView.elementKindGlobalFooter] = nil
            return 0
        }

        globalConfigurations[UICollectionView.elementKindGlobalFooter] = config

        let width = collectionView.bounds.width
        let target = CGSize(width: width, height: 0)

        config.configure(config.prototype, UICollectionView.globalElementIndexPath, .sizing)
        return config.prototype.systemLayoutSizeFitting(
            target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel).height
    }

}

extension CollectionViewWrapper {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)
        let strategy = sizingStrategy(for: localIndexPath.section, globalSection: indexPath.section, in: localDataSource)
        let config = cellConfiguration(for: localIndexPath, globalIndexPath: indexPath, dataSource: localDataSource)

        if let cached = strategy.cachedSize(forElementAt: indexPath) { return cached }

        let metrics = self.metrics(for: localIndexPath.section, globalSection: indexPath.section, in: localDataSource)
        let size = CGSize(width: collectionView.safeAreaLayoutGuide.layoutFrame.width, height: CGFloat.greatestFiniteMagnitude)
        let context = CollectionUISizingContext(prototype: config.prototype, indexPath: localIndexPath, layoutSize: size, metrics: metrics)

        config.configure(config.prototype, localIndexPath, .sizing)
        return strategy.size(forElementAt: localIndexPath, context: context, dataSource: localDataSource)
    }

    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)
        let config = cellConfiguration(for: localIndexPath, globalIndexPath: indexPath, dataSource: localDataSource)
        let type = Swift.type(of: config.prototype)

        switch config.dequeueSource {
        case .nib:
            collectionView.register(nibType: type, reuseIdentifier: config.reuseIdentifier)
        case .class:
            collectionView.register(classType: type, reuseIdentifier: config.reuseIdentifier)
        }

        return collectionView.dequeueReusableCell(withReuseIdentifier: config.reuseIdentifier, for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)

        // Check if the first or last item in this section is about to disappear
        #warning("when using a fetched results controller this crashes if you try and delete a non-last element")
//        if localIndexPath.item == 0 || localIndexPath.item - 1 == localDataSource.numberOfElements(in: localIndexPath.section) {
//            localDataSource.didEndDisplay()
//        }

        localDataSource.didEndDisplay(ofCell: cell, at: localIndexPath)
    }

    internal func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)

        // Check if an first or last item in this section is about to appear
        #warning("when using a fetched results controller this crashes at times")
//        if localIndexPath.item == 0 || localIndexPath.item - 1 == localDataSource.numberOfElements(in: localIndexPath.section) {
//            localDataSource.willBeginDisplay()
//        }

        let config = cellConfiguration(for: localIndexPath, globalIndexPath: indexPath, dataSource: localDataSource)
        config.configure(cell, localIndexPath, .presentation)

        localDataSource.willBeginDisplay(ofCell: cell, at: localIndexPath)

        guard let editable = dataSource as? EditHandlingDataSource, editable.supportsEditing(for: localIndexPath) else { return }
        (cell as? DataSourceEditableView)?.setEditing(editable.isEditing, animated: false)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let (localDataSource, localIndexPath) = dataSource.dataSourceFor(global: indexPath)
        return (localDataSource as? SelectionHandlingDataSource)?.shouldSelectElement(at: localIndexPath) ?? false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let (localDataSource, localIndexPath) = dataSource.dataSourceFor(global: indexPath)
        (localDataSource as? SelectionHandlingDataSource)?.selectElement(at: localIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        let (localDataSource, localIndexPath) = dataSource.dataSourceFor(global: indexPath)
        return (localDataSource as? SelectionHandlingDataSource)?.shouldDeselectElement(at: localIndexPath) ?? false
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let (localDataSource, localIndexPath) = dataSource.dataSourceFor(global: indexPath)
        (localDataSource as? SelectionHandlingDataSource)?.deselectElement(at: localIndexPath)
    }

}

private extension CollectionViewWrapper {

    func localDataSourceAndIndexPath(for global: IndexPath) -> (DataSource & CollectionUIProvidingDataSource, IndexPath) {
        let (localDataSource, localIndexPath) = dataSource.dataSourceFor(global: global)

        guard let dataSource = localDataSource as? DataSource & CollectionUIProvidingDataSource else {
            fatalError("The dataSource: (\(String(describing: localDataSource))), must conform to \(String(describing: CollectionUIProvidingDataSource.self))")
        }

        return (dataSource, localIndexPath)
    }

    func localDataSourceAndSection(for global: Int) -> (DataSource & CollectionUIProvidingDataSource, Int) {
        let (localDataSource, localSection) = dataSource.dataSourceFor(global: global)

        guard let dataSource = localDataSource as? DataSource & CollectionUIProvidingDataSource else {
            fatalError("The dataSource: (\(String(describing: localDataSource))), must conform to \(String(describing: CollectionUIProvidingDataSource.self))")
        }

        return (dataSource, localSection)
    }

    func metrics(for localSection: Int, globalSection: Int, in dataSource: CollectionUIProvidingDataSource) -> CollectionUISectionMetrics {
        if let metrics = self.metrics[globalSection] { return metrics }
        let metrics = dataSource.metrics(for: localSection)
        self.metrics[globalSection] = metrics
        return metrics
    }

    func sizingStrategy(for localSection: Int, globalSection: Int, in dataSource: CollectionUIProvidingDataSource) -> CollectionUISizingStrategy {
        if let strategy = sizingStrategies[globalSection] { return strategy }
        let strategy = dataSource.sizingStrategy(for: collectionView.traitCollection)
        sizingStrategies[globalSection] = strategy
        return strategy
    }

    func cellConfiguration(for localIndexPath: IndexPath, globalIndexPath: IndexPath, dataSource: CollectionUIProvidingDataSource) -> DataSourceUIConfiguration {
        if let configuration = cellConfigurations[globalIndexPath] { return configuration }
        let configuration = dataSource.cellConfiguration(for: localIndexPath)
        cellConfigurations[globalIndexPath] = configuration
        return configuration
    }

}

internal protocol DataReusableView: class {
    static var reuseIdentifier: String { get }
}

internal extension DataReusableView {
    static var reuseIdentifier: String { return String(describing: self) }
}

extension UICollectionReusableView: DataReusableView { }

private extension UICollectionView {
    func register(nibType: DataReusableView.Type, reuseIdentifier: String, kind: String? = nil) {
        let nib = UINib(nibName: String(describing: nibType), bundle: Bundle(for: nibType))

        if let kind = kind {
            register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: reuseIdentifier)
        } else {
            register(nib, forCellWithReuseIdentifier: reuseIdentifier)
        }
    }

    func register(classType: DataReusableView.Type, reuseIdentifier: String, kind: String? = nil) {
        if let kind = kind {
            register(classType, forSupplementaryViewOfKind: kind, withReuseIdentifier: reuseIdentifier)
        } else {
            register(classType, forCellWithReuseIdentifier: reuseIdentifier)
        }
    }
    
}

extension CollectionViewWrapper: DataSourceUpdateDelegate {

    ///    This is a little difficult to read and to see where the scopes exist.
    ///    But its highly efficient, so worthy of inclusion.
    ///
    ///    1. Grab all the local dataSources for each section inserted
    ///    2. Hash them to remove duplicates (since DS's can contain multiple sections)
    ///    3. Map them to DataSourceUILifecycleObserving
    ///    4. Call didBecomeActive
    private func lifecycleObservers(for sections: IndexSet, in dataSource: DataSource) -> [LifecycleObservingDataSource] {
        return sections
            .lazy
            .map { dataSource.dataSourceFor(global: $0) }
            .compactMap { $0.dataSource as? LifecycleObservingDataSource }
    }

    public func dataSourceDidReload(_ dataSource: DataSource) {
        // Update
        collectionView.reloadData()
        preparePlaceholderIfNeeded()
    }

    public func dataSource(_ dataSource: DataSource, performBatchUpdates updates: () -> Void, completion: ((Bool) -> Void)?) {
        collectionView.performBatchUpdates(updates, completion: completion)
    }

    public func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet) {
        collectionView.insertSections(sections)
        // if we have a new section, we just need to call prepare, didBecomeActive will be called by willDisplayCell at the appropriate time
        lifecycleObservers(for: sections, in: dataSource).forEach { $0.prepare() }
    }

    public func dataSource(_ dataSource: DataSource, didDeleteSections sections: IndexSet) {
        var hiddenSections = sections

        let attributes = collectionView.collectionViewLayout.layoutAttributesForElements(in: collectionView.bounds)
        attributes?.map { $0.indexPath }.forEach { hiddenSections.remove($0.section) }

        collectionView.deleteSections(sections)

        // The cell might not be visible, so we need to ask the dataSource to resign. If the cell was visible, this will trigger a 2nd call to willResignActive :(
        lifecycleObservers(for: hiddenSections, in: dataSource).forEach { $0.willResignActive() }
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

    public func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceInvalidationContext) {
        invalidate(with: context)
    }

    public func dataSource(_ dataSource: DataSource, globalFor local: IndexPath) -> (dataSource: DataSource, globalIndexPath: IndexPath) {
        return (self.dataSource, local)
    }

    public func dataSource(_ dataSource: DataSource, globalFor local: Int) -> (dataSource: DataSource, globalSection: Int) {
        return (self.dataSource, local)
    }

}
