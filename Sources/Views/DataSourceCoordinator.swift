import UIKit

#if canImport(FlowLayout)
import FlowLayout
extension DataSourceCoordinator: FlowLayoutDelegate { }
#else
extension DataSourceCoordinator: UICollectionViewDelegateFlowLayout { }
#endif

/// This coordinator provides the glue between a UICollectionView and a DataSource. Typically you would retain this on your UIViewController or use the provided DataSourceViewController which does this for you. This class handles all the coordination and updates as well as UICollectionView dataSource and delegate handling, ensuring relevant calls on your dataSource's performed.
public final class DataSourceCoordinator: NSObject, UICollectionViewDataSource {

    /// The collectionView associated with this coordinator
    public let collectionView: UICollectionView
    
    internal var globalProvider: SectionProvider!

    /// The dataSource associated with this coordinator
    public private(set) var dataSource: DataSource?

    private var globalConfigurations: [String: CollectionUIViewProvider] = [:]
    private var headerConfigurations: [Int: CollectionUIViewProvider] = [:]
    private var footerConfigurations: [Int: CollectionUIViewProvider] = [:]
    private var backgroundConfigurations: [Int: CollectionUIBackgroundProvider] = [:]
    private var cellConfigurations: [IndexPath: CollectionUIViewProvider] = [:]
    private var metrics: [Int: CollectionUISectionMetrics] = [:]
    private var sizingStrategies: [Int: CollectionUISizingStrategy] = [:]
    private var selectionHandlers: [IndexPath: SelectionContext] = [:]
    private var deselectionHandlers: [IndexPath: SelectionContext] = [:]

    /// Returns true if editing is currently enabled, false otherwise
    public private(set) var isEditing: Bool = false

    /// Make a new coordinator with the associated UICollectionView and DataSource
    ///
    /// - Parameter collectionView: The collectionView to associate with this coordinator
    /// - Parameter dataSource: The dataSource to associate with this coordinator
    public init(collectionView: UICollectionView, dataSource: DataSource? = nil) {
        self.collectionView = collectionView
        super.init()
        
        collectionView.isPrefetchingEnabled = true
        collectionView.allowsMultipleSelection = true
        collectionView.clipsToBounds = false

        if let dataSource = dataSource {
            replace(dataSource: dataSource)
        }
    }

    /// Replaces the current dataSource
    ///
    /// - Parameter dataSource: The new dataSource to associate with this coordinator
    public func replace(dataSource: DataSource) {
        self.dataSource = dataSource
        dataSource.updateDelegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        preparePlaceholderIfNeeded()
    }

    @objc public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource?.numberOfSections ?? 0
    }

    @objc public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfElements(in: section) ?? 0
    }

    /// Sets editing on the collectionView and dataSource
    ///
    /// - Parameters:
    ///   - editing: True to enable editing, false otherwise
    ///   - animated: If true, the collectionView will animate its state
    public func setEditing(_ editing: Bool, animated: Bool) {
        isEditing = editing
        guard let dataSource = dataSource else { return }

        #if canImport(FlowLayout)
        let globalHeader = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalHeader, at: UICollectionView.globalElementIndexPath)
        let globalFooter = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalFooter, at: UICollectionView.globalElementIndexPath)
        #endif

        let headers = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)
        let footers = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter)

        #if canImport(FlowLayout)
        let elements = [globalHeader, globalFooter]
        #else
        let elements: [UICollectionReusableView?] = []
        #endif

        [elements
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

    /// Invalidates the dataSource, collectionView and associated layout using the specified context
    ///
    /// - Parameter context: The context that defines the level of invalidation to perform
    public func invalidate(with context: DataSourceInvalidationContext) {
        defer {
            #if canImport(FlowLayout)
            if context.invalidateGlobalHeaderData, let view = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalHeader, at: UICollectionView.globalElementIndexPath) {
                globalConfigurations[UICollectionView.elementKindGlobalHeader]?.configure(view, UICollectionView.globalElementIndexPath, .presentation)
            }

            if context.invalidateGlobalFooterData, let view = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalFooter, at: UICollectionView.globalElementIndexPath) {
                globalConfigurations[UICollectionView.elementKindGlobalFooter]?.configure(view, UICollectionView.globalElementIndexPath, .presentation)
            }
            #endif
        }

        context.refreshElementsIndexPaths.forEach {
            guard let cell = collectionView.cellForItem(at: $0) else { return }
            let local = localDataSourceAndIndexPath(for: $0)
            cellConfigurations[$0]?.configure(cell, local.1, .presentation)
        }

        context.refreshHeaderIndexes.forEach {
            let indexPath = IndexPath(item: 0, section: $0)
            let kind = UICollectionView.elementKindSectionHeader
            guard let view = collectionView.supplementaryView(forElementKind: kind, at: indexPath) else { return }
            headerConfigurations[$0]?.configure(view, indexPath, .presentation)
        }

        context.refreshFooterIndexes.forEach {
            let indexPath = IndexPath(item: 0, section: $0)
            let kind = UICollectionView.elementKindSectionFooter
            guard let view = collectionView.supplementaryView(forElementKind: kind, at: indexPath) else { return }
            footerConfigurations[$0]?.configure(view, indexPath, .presentation)
        }

        #if canImport(FlowLayout)
        let layoutContext = FlowLayoutInvalidationContext()
        layoutContext.invalidateGlobalHeader = context.invalidateGlobalHeaderMetrics
        layoutContext.invalidateGlobalFooter = context.invalidateGlobalFooterMetrics
        #else
        let layoutContext = UICollectionViewFlowLayoutInvalidationContext()
        #endif
        
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

        if context.invalidateLayoutMetrics {
            sizingStrategies.removeAll()
            metrics.removeAll()
        }

        collectionView.performBatchUpdates({
            collectionView.collectionViewLayout.invalidateLayout(with: layoutContext)
        }, completion: nil)
    }

    private func preparePlaceholderIfNeeded() {
        guard dataSource?.isEmpty == true,
            let config = (dataSource as? GlobalViewsProvidingDataSource)?.placeholderConfiguration() else {
                collectionView.backgroundView = nil
                return
        }
        
        config.configure(config.prototype, IndexPath(item: 0, section: 0), .presentation)
        collectionView.backgroundView = config.prototype
    }

}

public extension DataSourceCoordinator {

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

public extension DataSourceCoordinator {

    #if canImport(FlowLayout)
    func backgroundLayoutRegion(in collectionView: UICollectionView, forSectionAt section: Int) -> BackgroundLayoutRegion {
        let (localDataSource, localSection) = localDataSourceAndSection(for: section)
        
        guard !localDataSource.isEmbedded,
            let config = backgroundConfigurations[section] ?? localDataSource.backgroundConfiguration(for: localSection) else {
                backgroundConfigurations[section] = nil
                return .none
        }
        
        let type = Swift.type(of: config.prototype)
        switch config.dequeueMethod {
        case .nib:
            collectionView.register(nibType: type, reuseIdentifier: config.reuseIdentifier, kind: UICollectionView.elementKindBackground)
        case .class:
            collectionView.register(classType: type, reuseIdentifier: config.reuseIdentifier, kind: UICollectionView.elementKindBackground)
        case .storyboard:
            fatalError("Configuring a background to load via a storyboard is not supported. Please use either the `nib` or `class` methods.")
        }
        
        backgroundConfigurations[section] = config
        return config.style
    }
    
    func backgroundLayoutInsets(in collectionView: UICollectionView, forSectionAt section: Int) -> UIEdgeInsets {
        let (localDataSource, localSection) = localDataSourceAndSection(for: section)
        
        guard !localDataSource.isEmbedded,
            let config = backgroundConfigurations[section] ?? localDataSource.backgroundConfiguration(for: localSection) else {
                backgroundConfigurations[section] = nil
                return .zero
        }
        
        backgroundConfigurations[section] = config
        return config.insets
    }
    #endif

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

        let width = collectionView.bounds.width
        let target = CGSize(width: width, height: 0)

        config.configure(config.prototype, IndexPath(item: 0, section: localSection), .sizing)
        return config.prototype.systemLayoutSizeFitting(
            target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)

        #if canImport(FlowLayout)
        switch elementKind {
        case UICollectionView.elementKindBackground:
            guard let config = localDataSource.backgroundConfiguration(for: localIndexPath.section) else { return }
            config.configure(view, localIndexPath, .presentation)
        default:
            break
        }
        #endif
        
        if isEditing, let editable = localDataSource as? EditHandlingDataSource {
            (view as? EditHandling)?.setEditing(editable.isEditing, animated: false)
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var configuration: CollectionUIViewProvider?
        var sectionDataSource: DataSource
        var indexPathRelativeToSectionDataSource: IndexPath

        switch (kind, dataSource) {
        case (UICollectionView.elementKindSectionHeader, _):
            let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)
            configuration = headerConfigurations[indexPath.section]
                ?? localDataSource.headerConfiguration(for: localIndexPath.section)
            sectionDataSource = localDataSource
            indexPathRelativeToSectionDataSource = localIndexPath

        case (UICollectionView.elementKindSectionFooter, _):
            let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)
            configuration = footerConfigurations[indexPath.section]
                ?? localDataSource.footerConfiguration(for: localIndexPath.section)
            sectionDataSource = localDataSource
            indexPathRelativeToSectionDataSource = localIndexPath
        default:
            #if canImport(FlowLayout)
            switch (kind, dataSource) {
            case let (UICollectionView.elementKindGlobalHeader, dataSource as GlobalViewsProvidingDataSource):
                configuration = globalConfigurations[kind]
                    ?? dataSource.globalHeaderConfiguration()
                sectionDataSource = dataSource
                indexPathRelativeToSectionDataSource = indexPath

            case let (UICollectionView.elementKindGlobalFooter, dataSource as GlobalViewsProvidingDataSource):
                configuration = globalConfigurations[kind]
                    ?? dataSource.globalFooterConfiguration()
                sectionDataSource = dataSource
                indexPathRelativeToSectionDataSource = indexPath

            case (UICollectionView.elementKindBackground, _):
                let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)
                configuration = backgroundConfigurations[indexPath.section]
                    ?? localDataSource.backgroundConfiguration(for: localIndexPath.section)
                sectionDataSource = localDataSource
                indexPathRelativeToSectionDataSource = localIndexPath
            default:
                fatalError("Unsupported supplementary view kind: \(kind) at indexPath: \(indexPath). Only global and section header/footer views are supported.")
            }
            #endif
        }

        guard let config = configuration else {
            fatalError("Supported kind: \(kind) did not return a view for indexPath: \(indexPath)")
        }

        let type = Swift.type(of: config.prototype)
        switch config.dequeueMethod {
        case .nib:
            collectionView.register(nibType: type, reuseIdentifier: config.reuseIdentifier, kind: kind)
        case .class:
            collectionView.register(classType: type, reuseIdentifier: config.reuseIdentifier, kind: kind)
        case .storyboard:
            fatalError("Configuring a header, footer or global element to load via a storyboard is not supported. Please use either the `nib` or `class` methods.")
        }

        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: config.reuseIdentifier, for: indexPath)
        configuration?.configure(view, indexPathRelativeToSectionDataSource, .presentation)

        if isEditing, let editable = sectionDataSource as? EditHandlingDataSource {
            (view as? EditHandling)?.setEditing(editable.isEditing, animated: false)
        }

        return view
    }

}

public extension DataSourceCoordinator {

    #if canImport(FlowLayout)
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
    #endif

}

public extension DataSourceCoordinator {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)
        let layoutSize = CGSize(width: collectionView.safeAreaLayoutGuide.layoutFrame.width, height: collectionView.bounds.height)

        let metrics = self.metrics(for: localIndexPath.section, globalSection: indexPath.section, in: localDataSource)
        let strategy = sizingStrategy(for: localIndexPath.section, globalSection: indexPath.section, in: localDataSource)

        if let cached = strategy.cachedSize(forElementAt: indexPath) { return cached }
        let config = cellConfiguration(for: localIndexPath, globalIndexPath: indexPath, dataSource: localDataSource)

        let context = CollectionUISizingContext(prototype: config.prototype,
                                                indexPath: localIndexPath,
                                                layoutSize: layoutSize,
                                                metrics: metrics,
                                                traitCollection: collectionView.traitCollection)

        config.configure(config.prototype, localIndexPath, .sizing)
        return strategy.size(forElementAt: localIndexPath, context: context, dataSource: localDataSource)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard isEditing else { return }
        let (localDataSource, _) = localDataSourceAndIndexPath(for: indexPath)
        guard let editable = localDataSource as? EditHandlingDataSource else { return }
        (cell as? EditHandling)?.setEditing(editable.isEditing, animated: false)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let (localDataSource, localIndexPath) = localDataSourceAndIndexPath(for: indexPath)
        let config = cellConfiguration(for: localIndexPath, globalIndexPath: indexPath, dataSource: localDataSource)
        let type = Swift.type(of: config.prototype)

        switch config.dequeueMethod {
        case .nib:
            collectionView.register(nibType: type, reuseIdentifier: config.reuseIdentifier)
        case .class:
            collectionView.register(classType: type, reuseIdentifier: config.reuseIdentifier)
        case .storyboard:
            break // storyboard's auto-register their cells
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: config.reuseIdentifier, for: indexPath)
        config.configure(cell, localIndexPath, .presentation)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let dataSource = dataSource else { return false }
        let (localDataSource, localSection) = dataSource.localSection(for: indexPath.section)
        let localIndexPath = IndexPath(item: indexPath.item, section: localSection)
        
        guard let selectionDataSource = localDataSource as? SelectionHandlingDataSource,
            let handler = selectionDataSource.selectionHandler(forElementAt: localIndexPath) else { return false }
        selectionHandlers[indexPath] = SelectionContext(localDataSource: selectionDataSource, localIndexPath: localIndexPath, handler: handler)

        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let dataSource = dataSource, let context = selectionHandlers[indexPath] else { return }

        let selectedIndexPaths = (collectionView.indexPathsForSelectedItems ?? []).filter { $0 != indexPath }
        let indexPaths = collectionView.localIndexPaths(for: selectedIndexPaths, globalDataSource: dataSource, localDataSource: context.localDataSource)

        if !context.localDataSource.allowsMultipleSelection {
            indexPaths.forEach { collectionView.deselectItem(at: $0.global, animated: true) }
        }

        context.handler()
        selectionHandlers[indexPath] = nil
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard let dataSource = dataSource else { return false }
        let (localDataSource, localSection) = dataSource.localSection(for: indexPath.section)
        let localIndexPath = IndexPath(item: indexPath.item, section: localSection)

        guard let selectionDataSource = localDataSource as? SelectionHandlingDataSource,
            selectionDataSource.allowsMultipleSelection,
            let handler = selectionDataSource.deselectionHandler(forElementAt: localIndexPath) else { return false }
        deselectionHandlers[indexPath] = SelectionContext(localDataSource: selectionDataSource, localIndexPath: localIndexPath, handler: handler)

        return true
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let context = deselectionHandlers[indexPath] {
            context.handler()
            deselectionHandlers[indexPath] = nil
        }
    }

}

private extension DataSourceCoordinator {

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
        let metrics = dataSource.metrics(for: localSection, traitCollection: collectionView.traitCollection, layoutSize: collectionView.bounds.size)
        self.metrics[globalSection] = metrics
        return metrics
    }

    func sizingStrategy(for localSection: Int, globalSection: Int, in dataSource: CollectionUIProvidingDataSource) -> CollectionUISizingStrategy {
        let strategy = dataSource.sizingStrategy(for: collectionView.traitCollection, layoutSize: collectionView.bounds.size)
        sizingStrategies[globalSection] = strategy
        return strategy
    }

    func cellConfiguration(for localIndexPath: IndexPath, globalIndexPath: IndexPath, dataSource: CollectionUIProvidingDataSource) -> CollectionUIViewProvider {
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

extension DataSourceCoordinator: DataSourceUpdateDelegate {

    public func dataSource(_ dataSource: DataSource, performUpdates changeDetails: ComposedChangeDetails) {
        var changeDetails = changeDetails

        defer {
            preparePlaceholderIfNeeded()
        }

        guard changeDetails.hasIncrementalChanges else {
            collectionView.reloadData()
            return
        }
        
        let newAndOldSectionIndexes = changeDetails.removedSections.union(changeDetails.insertedSections)

        collectionView.performBatchUpdates({
            collectionView.deleteSections(changeDetails.removedSections)
            collectionView.insertSections(changeDetails.insertedSections)
            collectionView.reloadSections(changeDetails.updatedSections)

            changeDetails.enumerateMovedSections { source, target in
                collectionView.moveSection(source, toSection: target)
            }

            // we need to filter out item level updates that will implicitly be handled by the section updates above
            // otherwise UICollectionView results in odd animations and this often leads to 'ghost' layers in the hierarchy
            let deleted = changeDetails.removedIndexPaths.filter { !newAndOldSectionIndexes.contains($0.section) }
            let inserted = changeDetails.insertedIndexPaths.filter { !newAndOldSectionIndexes.contains($0.section) }
                
            collectionView.deleteItems(at: deleted)
            collectionView.insertItems(at: inserted)

            changeDetails.enumerateMovedIndexPaths { source, target in
                collectionView.moveItem(at: source, to: target)
            }
        }, completion: { _ in
            self.collectionView.reloadItems(at: changeDetails.updatedIndexPaths)
        })
    }

    public func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceInvalidationContext) {
        invalidate(with: context)
    }

    public func dataSource(_ dataSource: DataSource, sectionFor local: Int) -> (dataSource: DataSource, globalSection: Int) {
        guard let dataSource = self.dataSource else { fatalError("This should never be called when dataSource == nil") }
        return (dataSource, local)
    }

}
