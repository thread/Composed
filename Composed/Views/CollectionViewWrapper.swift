import UIKit

internal final class CollectionViewWrapper: NSObject, UICollectionViewDataSource, FlowLayoutDelegate {

    internal let collectionView: UICollectionView

    private(set) var dataSource: DataSource? {
        didSet {
            dataSource?.updateDelegate = self
            collectionView.delegate = self
            collectionView.dataSource = self
        }
    }

    private var globalConfigurations: [String: CollectionUIViewProvider] = [:]
    private var headerConfigurations: [Int: CollectionUIViewProvider] = [:]
    private var footerConfigurations: [Int: CollectionUIViewProvider] = [:]
    private var cellConfigurations: [IndexPath: CollectionUIViewProvider] = [:]
    private var metrics: [Int: CollectionUISectionMetrics] = [:]
    private var sizingStrategies: [Int: CollectionUISizingStrategy] = [:]

    private var isEditing: Bool = false

    internal init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        collectionView.isPrefetchingEnabled = true
        collectionView.allowsMultipleSelection = true
        collectionView.clipsToBounds = false
    }

    internal func replace(dataSource: DataSource) {
        self.dataSource = dataSource
    }

    @objc internal func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource?.numberOfSections ?? 0
    }

    @objc public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfElements(in: section) ?? 0
    }

    internal func setEditing(_ editing: Bool, animated: Bool) {
        isEditing = editing
        guard let dataSource = dataSource else { return }

        let globalHeader = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalHeader, at: UICollectionView.globalElementIndexPath)
        let globalFooter = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalFooter, at: UICollectionView.globalElementIndexPath)
        let headers = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)
        let footers = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter)

        [[globalHeader, globalFooter]
            .lazy
            .compactMap { $0 }, headers, footers]
            .flatMap { $0 }
            .compactMap { $0 as? EditHandling }
            .forEach { $0.setEditing(editing, animated: animated) }

        let indexPaths = collectionView.collectionViewLayout.layoutAttributesForElements(in: collectionView.bounds) ?? []

        let itemIndexPaths = Set(
            indexPaths
                .lazy
                .filter { $0.representedElementCategory == .cell }
                .map { $0.indexPath }
                .sorted()
        )

        let sections = Set(indexPaths.map { $0.indexPath.section })

        for global in sections {
            let (localDataSource, _) = dataSource.localSection(for: global)

            if let dataSource = localDataSource as? EditHandlingDataSource {
                dataSource.setEditing(editing, animated: animated)
            }
        }

        for global in itemIndexPaths {
            let cell = collectionView.cellForItem(at: global) as? EditHandling
            cell?.setEditing(editing, animated: animated)
        }
    }

    internal func invalidate(with context: DataSourceInvalidationContext) {
        defer {
            if context.invalidateGlobalHeaderData, let view = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalHeader, at: UICollectionView.globalElementIndexPath) {
                globalConfigurations[UICollectionView.elementKindGlobalHeader]?.configure(view, UICollectionView.globalElementIndexPath, .presentation)
            }

            if context.invalidateGlobalFooterData, let view = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalFooter, at: UICollectionView.globalElementIndexPath) {
                globalConfigurations[UICollectionView.elementKindGlobalFooter]?.configure(view, UICollectionView.globalElementIndexPath, .presentation)
            }
        }

        context.reloadingElementIndexPaths.forEach {
            guard let cell = collectionView.cellForItem(at: $0) else { return }
            let local = localDataSourceAndIndexPath(for: $0)
            cellConfigurations[$0]?.configure(cell, local.1, .presentation)
        }

        context.reloadingHeaderIndexes.forEach {
            let indexPath = IndexPath(item: 0, section: $0)
            let kind = UICollectionView.elementKindSectionHeader
            guard let view = collectionView.supplementaryView(forElementKind: kind, at: indexPath) else { return }
            headerConfigurations[$0]?.configure(view, indexPath, .presentation)
        }

        context.reloadingFooterIndexes.forEach {
            let indexPath = IndexPath(item: 0, section: $0)
            let kind = UICollectionView.elementKindSectionFooter
            guard let view = collectionView.supplementaryView(forElementKind: kind, at: indexPath) else { return }
            footerConfigurations[$0]?.configure(view, indexPath, .presentation)
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

    private func preparePlaceholderIfNeeded() {
        collectionView.backgroundView = dataSource?.isEmpty == true
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
        // We can rely on the fact that sections will be queried first and only when the whole section was invalidated.
        // Therefore its safe to say we should purge any caches we hold onto based on sections and lazily re-query them at a later time.
        sizingStrategies[section] = nil
        metrics[section] = nil

        let (localDataSource, localSection) = localDataSourceAndSection(for: section)
        if localDataSource.isEmbedded { return .zero }

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
        if localDataSource.isEmbedded { return .zero }

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
        let configuration: CollectionUIViewProvider?
        let sectionDataSource: DataSource?

        switch (kind, dataSource) {
        case let (UICollectionView.elementKindGlobalHeader, dataSource as GlobalViewsProvidingDataSource):
            configuration = globalConfigurations[kind]
                ?? dataSource.globalHeaderConfiguration()
            sectionDataSource = dataSource

        case let (UICollectionView.elementKindGlobalFooter, dataSource as GlobalViewsProvidingDataSource):
            configuration = globalConfigurations[kind]
                ?? dataSource.globalFooterConfiguration()
            sectionDataSource = dataSource

        case (UICollectionView.elementKindSectionHeader, _):
            let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)
            configuration = headerConfigurations[indexPath.section]
                ?? localDataSource.headerConfiguration(for: localIndexPath.section)
            sectionDataSource = localDataSource

        case (UICollectionView.elementKindSectionFooter, _):
            let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)
            configuration = footerConfigurations[indexPath.section]
                ?? localDataSource.footerConfiguration(for: localIndexPath.section)
            sectionDataSource = localDataSource

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

        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: config.reuseIdentifier, for: indexPath)
        configuration?.configure(view, indexPath, .presentation)

        if isEditing, let editable = sectionDataSource as? EditHandlingDataSource {
            (view as? EditHandling)?.setEditing(editable.isEditing, animated: false)
        }

        return view
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
        let layoutSize = CGSize(width: collectionView.safeAreaLayoutGuide.layoutFrame.width, height: collectionView.bounds.height)

        if let embedding = localDataSource as? EmbeddingDataSource {
            let dataSource = embedding.embedded.child
            let strategy = dataSource.sizingStrategy(in: collectionView)
            let metrics = dataSource.metrics(for: 0)
            let cellConfig = dataSource.cellConfiguration(for: IndexPath(item: 0, section: 0))

            let layoutSize = CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
            let context = CollectionUISizingContext(prototype: cellConfig.prototype,
                                                    indexPath: IndexPath(item: 0, section: 0),
                                                    layoutSize: layoutSize,
                                                    metrics: metrics)

            let size = strategy.size(forElementAt: IndexPath(item: 0, section: 0), context: context, dataSource: dataSource)
            return CGSize(width: layoutSize.width, height: size.height + metrics.insets.top + metrics.insets.bottom)
        }

        let metrics = self.metrics(for: localIndexPath.section, globalSection: indexPath.section, in: localDataSource)
        let strategy = sizingStrategy(for: localIndexPath.section, globalSection: indexPath.section, in: localDataSource)

        if let cached = strategy.cachedSize(forElementAt: indexPath) { return cached }
        let config = cellConfiguration(for: localIndexPath, globalIndexPath: indexPath, dataSource: localDataSource)

        let context = CollectionUISizingContext(prototype: config.prototype, indexPath: localIndexPath, layoutSize: layoutSize, metrics: metrics)

        config.configure(config.prototype, localIndexPath, .sizing)
        return strategy.size(forElementAt: localIndexPath, context: context, dataSource: localDataSource)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard isEditing else { return }
        let (localDataSource, _) = localDataSourceAndIndexPath(for: indexPath)
        guard let editable = localDataSource as? EditHandlingDataSource else { return }
        (cell as? EditHandling)?.setEditing(editable.isEditing, animated: false)
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

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: config.reuseIdentifier, for: indexPath)
        config.configure(cell, localIndexPath, .presentation)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let dataSource = dataSource else { return false }
        let (localDataSource, localSection) = dataSource.localSection(for: indexPath.section)
        let localIndexPath = IndexPath(item: indexPath.item, section: localSection)
        return (localDataSource as? SelectionHandlingDataSource)?.shouldSelectElement(at: localIndexPath) ?? false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let dataSource = dataSource else { return }
        let (localDataSource, localSection) = dataSource.localSection(for: indexPath.section)
        let localIndexPath = IndexPath(item: indexPath.item, section: localSection)
        guard let selectionDataSource = localDataSource as? SelectionHandlingDataSource else { return }

        #warning("Implement both single and multiple selection handling")
//        if !selectionDataSource.allowsMultipleSelection {
//            let selectedIndexPathsInSection = (collectionView.indexPathsForSelectedItems ?? [])
//                .filter { $0.section == indexPath.section && $0 != indexPath }
//
//
//            mapping.localIndexPaths(forGlobal: selectedIndexPathsInSection).forEach {
//                selectionDataSource.deselectElement(at: $0)
//            }
//
//            selectedIndexPathsInSection.forEach {
//                collectionView.deselectItem(at: $0, animated: true)
//            }
//        }

        selectionDataSource.selectElement(at: localIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard let dataSource = dataSource else { return false }
        let (localDataSource, localSection) = dataSource.localSection(for: indexPath.section)
        let localIndexPath = IndexPath(item: indexPath.item, section: localSection)
        return (localDataSource as? SelectionHandlingDataSource)?.shouldDeselectElement(at: localIndexPath) ?? false
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let dataSource = dataSource else { return }
        let (localDataSource, localSection) = dataSource.localSection(for: indexPath.section)
        let localIndexPath = IndexPath(item: indexPath.item, section: localSection)
        (localDataSource as? SelectionHandlingDataSource)?.deselectElement(at: localIndexPath)
    }

}

private extension CollectionViewWrapper {

    func localDataSourceAndIndexPath(for global: IndexPath) -> (DataSource & CollectionUIProvidingDataSource, IndexPath) {
        guard let rootDataSource = dataSource else { fatalError("No dataSource appears to be attached to this wrapper" ) }
        let (localDataSource, localSection) = rootDataSource.localSection(for: global.section)
        let localIndexPath = IndexPath(item: global.item, section: localSection)

        guard let dataSource = localDataSource as? DataSource & CollectionUIProvidingDataSource else {
            fatalError("The dataSource: (\(String(describing: localDataSource))), must conform to \(String(describing: CollectionUIProvidingDataSource.self))")
        }

        return (dataSource, localIndexPath)
    }

    func localDataSourceAndSection(for global: Int) -> (DataSource & CollectionUIProvidingDataSource, Int) {
        guard let rootDataSource = dataSource else { fatalError("No dataSource appears to be attached to this wrapper") }
        let (localDataSource, localSection) = rootDataSource.localSection(for: global)

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
        let strategy = dataSource.sizingStrategy(in: collectionView)
        sizingStrategies[globalSection] = strategy
        return strategy
    }

    func cellConfiguration(for localIndexPath: IndexPath, globalIndexPath: IndexPath, dataSource: CollectionUIProvidingDataSource) -> CollectionUIViewProvider {
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

    private func lifecycleObservers(for sections: IndexSet, in dataSource: DataSource) -> [LifecycleObservingDataSource] {
        return sections
            .lazy
            .map { dataSource.localSection(for: $0) }
            .compactMap { $0.dataSource as? LifecycleObservingDataSource }
    }

    func dataSource(_ dataSource: DataSource, performUpdates changeDetails: ComposedChangeDetails) {
        var changeDetails = changeDetails

        defer {
            preparePlaceholderIfNeeded()
        }

        guard changeDetails.hasIncrementalChanges else {
            collectionView.reloadData()
            return
        }

        collectionView.performBatchUpdates({
            collectionView.deleteSections(changeDetails.removedSections)
            collectionView.insertSections(changeDetails.insertedSections)
            collectionView.reloadSections(changeDetails.updatedSections)

            changeDetails.enumerateMovedSections { source, target in
                collectionView.moveSection(source, toSection: target)
            }

            collectionView.deleteItems(at: changeDetails.removedIndexPaths)
            collectionView.insertItems(at: changeDetails.insertedIndexPaths)
            collectionView.reloadItems(at: changeDetails.updatedIndexPaths)

            changeDetails.enumerateMovedIndexPaths { source, target in
                collectionView.moveItem(at: source, to: target)
            }
        }, completion: nil)
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
        var context = DataSourceInvalidationContext()
        context.reloadElements(at: indexPaths)
        invalidate(with: context)
    }

    public func dataSource(_ dataSource: DataSource, didMoveFromIndexPath from: IndexPath, toIndexPath to: IndexPath) {
        collectionView.moveItem(at: from, to: to)
    }

    public func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceInvalidationContext) {
        invalidate(with: context)
    }

    public func dataSource(_ dataSource: DataSource, sectionFor local: Int) -> (dataSource: DataSource, globalSection: Int) {
        guard let dataSource = self.dataSource else { fatalError("This should never be called when dataSource == nil") }
        return (dataSource, local)
    }

}
