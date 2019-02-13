public protocol DataReusableView: class {
    static var reuseIdentifier: String { get }
}

public extension DataReusableView {
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

public protocol DataSourceViewDelegate: class {
    func collectionView(_ collectionView: UICollectionView, didScrollTo contentOffset: CGPoint)
    func collectionView(_ collectionView: UICollectionView, didSelectItem indexPath: IndexPath)
    func collectionView(_ collectionView: UICollectionView, didDeselectItem indexPath: IndexPath)
}

public extension DataSourceViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didScrollTo contentOffset: CGPoint) { }
    func collectionView(_ collectionView: UICollectionView, didSelectItem indexPath: IndexPath) { }
    func collectionView(_ collectionView: UICollectionView, didDeselectItem indexPath: IndexPath) { }
}

internal final class CollectionViewWrapper: NSObject, UICollectionViewDataSource, FlowLayoutDelegate {

    internal let collectionView: UICollectionView
    internal let dataSource: DataSource
    internal weak var delegate: DataSourceViewDelegate?

    private var globalConfigurations: [String: DataSourceUIConfiguration] = [:]
    private var headerConfigurations: [Int: DataSourceUIConfiguration] = [:]
    private var footerConfigurations: [Int: DataSourceUIConfiguration] = [:]
    private var cellConfigurations: [IndexPath: DataSourceUIConfiguration] = [:]

    internal init(collectionView: UICollectionView, dataSource: DataSource) {
        self.collectionView = collectionView
        self.dataSource = dataSource

        super.init()

        collectionView.delegate = self
        collectionView.dataSource = self
    }

    @objc internal func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSections
    }

    @objc public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfElements(in: section)
    }

    internal func setEditing(_ editing: Bool, animated: Bool) {
        let globalHeader = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalHeader, at: UICollectionView.globalElementIndexPath)
        let globalFooter = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindGlobalFooter, at: UICollectionView.globalElementIndexPath)
        let headers = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)
        let footers = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter)

        [[globalHeader, globalFooter]
            .lazy
            .compactMap { $0 }, headers, footers]
            .flatMap { $0 }
            .compactMap { $0 as? DataSourceUIEditingCell }
            .forEach { $0.setEditing(editing, animated: animated) }

        let itemIndexPaths = collectionView.indexPathsForVisibleItems

        for global in itemIndexPaths {
            let (localDataSource, local) = self.dataSource.dataSourceFor(global: global)

            guard let dataSource = localDataSource as? DataSourceUIEditing,
                dataSource.supportsEditing(for: local) else { continue }

            dataSource.setEditing(editing, animated: animated)

            let cell = collectionView.cellForItem(at: global) as? DataSourceUIEditingCell
            cell?.setEditing(editing, animated: animated)
        }
    }

    internal func invalidate(with context: DataSourceUIInvalidationContext) {
        let layoutContext = FlowLayoutInvalidationContext()
        layoutContext.invalidateItems(at: Array(context.invalidatedElementIndexPaths))

        let headerIndexPaths = context.invalidatedHeaderIndexes.map { IndexPath(item: 0, section: $0) }
        if !headerIndexPaths.isEmpty {
            layoutContext.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader, at: headerIndexPaths)
        }

        let footerIndexPaths = context.invalidatedFooterIndexes.map { IndexPath(item: 0, section: $0) }
        if !footerIndexPaths.isEmpty {
            layoutContext.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionFooter, at: footerIndexPaths)
        }

        layoutContext.invalidateGlobalHeader = context.invalidateGlobalHeader
        layoutContext.invalidateGlobalFooter = context.invalidateGlobalFooter

        collectionView.collectionViewLayout.invalidateLayout(with: layoutContext)
    }

}

extension CollectionViewWrapper {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let (localDataSource, localSection) = self.dataSource.dataSourceFor(global: section)

        guard let dataSource = localDataSource as? DataSource & DataSourceUIProviding else {
            fatalError("The dataSource: (\(String(describing: localDataSource))), must conform to \(String(describing: DataSourceUIProviding.self))")
        }

        return dataSource.metrics(for: localSection).insets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let (localDataSource, localSection) = self.dataSource.dataSourceFor(global: section)

        guard let dataSource = localDataSource as? DataSource & DataSourceUIProviding else {
            fatalError("The dataSource: (\(String(describing: localDataSource))), must conform to \(String(describing: DataSourceUIProviding.self))")
        }

        return dataSource.metrics(for: localSection).horizontalSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let (localDataSource, localSection) = self.dataSource.dataSourceFor(global: section)

        guard let dataSource = localDataSource as? DataSource & DataSourceUIProviding else {
            fatalError("The dataSource: (\(String(describing: localDataSource))), must conform to \(String(describing: DataSourceUIProviding.self))")
        }

        return dataSource.metrics(for: localSection).verticalSpacing
    }

}

extension CollectionViewWrapper {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let (localDataSource, localSection) = dataSource.dataSourceFor(global: section)

        guard let dataSource = localDataSource as? DataSource & DataSourceUIProviding else {
            fatalError("The dataSource: (\(String(describing: localDataSource))), must conform to \(String(describing: DataSourceUIProviding.self))")
        }

        guard let config = dataSource.headerConfiguration(for: localSection) else { return .zero }
        headerConfigurations[section] = config

        let width = collectionView.bounds.width
        let target = CGSize(width: width, height: 0)

        config.configure(config.prototype, IndexPath(item: 0, section: localSection))
        return config.prototype.systemLayoutSizeFitting(
            target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let (localDataSource, localSection) = self.dataSource.dataSourceFor(global: section)

        guard let dataSource = localDataSource as? DataSource & DataSourceUIProviding else {
            fatalError("The dataSource: (\(String(describing: localDataSource))), must conform to \(String(describing: DataSourceUIProviding.self))")
        }

        guard let config = dataSource.footerConfiguration(for: localSection) else { return .zero }
        footerConfigurations[section] = config

        let width = collectionView.bounds.width
        let target = CGSize(width: width, height: 0)

        config.configure(config.prototype, IndexPath(item: 0, section: localSection))
        return config.prototype.systemLayoutSizeFitting(
            target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let global = self.dataSource as? GlobalDataSource
        let (localDataSource, localIndexPath) = self.dataSource.dataSourceFor(global: indexPath)

        guard let dataSource = localDataSource as? DataSource & DataSourceUIProviding else {
            fatalError("The dataSource: (\(String(describing: localDataSource))), must conform to \(String(describing: DataSourceUIProviding.self))")
        }

        let configuration: DataSourceUIConfiguration?

        switch kind {
        case UICollectionView.elementKindGlobalHeader:
            configuration = globalConfigurations[kind]
                ?? global?.globalHeaderConfiguration
        case UICollectionView.elementKindGlobalFooter:
            configuration = globalConfigurations[kind]
                ?? global?.globalFooterConfiguration
        case UICollectionView.elementKindSectionHeader:
            configuration = headerConfigurations[indexPath.section] 
                ?? dataSource.headerConfiguration(for: localIndexPath.section)
        case UICollectionView.elementKindSectionFooter:
            configuration = footerConfigurations[indexPath.section]
                ?? dataSource.footerConfiguration(for: localIndexPath.section)
        default: fatalError("Unsupported")
        }

        guard let config = configuration else { fatalError() }

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
        let global = dataSource as? GlobalDataSource
        let (localDataSource, localIndexPath) = self.dataSource.dataSourceFor(global: indexPath)

        guard let dataSource = localDataSource as? DataSource & DataSourceUIProviding else {
            fatalError("The dataSource: (\(String(describing: localDataSource))), must conform to \(String(describing: DataSourceUIProviding.self))")
        }

        switch elementKind {
        case UICollectionView.elementKindGlobalHeader:
            let config = global?.globalHeaderConfiguration
            config?.configure(view, UICollectionView.globalElementIndexPath)
        case UICollectionView.elementKindGlobalFooter:
            let config = global?.globalFooterConfiguration
            config?.configure(view, UICollectionView.globalElementIndexPath)
        case UICollectionView.elementKindSectionHeader:
            let config = dataSource.headerConfiguration(for: localIndexPath.section)
            config?.configure(view, localIndexPath)
        case UICollectionView.elementKindSectionFooter:
            let config = dataSource.footerConfiguration(for: localIndexPath.section)
            config?.configure(view, localIndexPath)
        default:
            break
        }
    }

}

extension CollectionViewWrapper {

    func heightForGlobalHeader(in collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout) -> CGFloat {
        guard let config = (dataSource as? GlobalDataSource)?.globalHeaderConfiguration else { return 0 }
        globalConfigurations[UICollectionView.elementKindGlobalHeader] = config

        let width = collectionView.bounds.width
        let target = CGSize(width: width, height: 0)

        config.configure(config.prototype, UICollectionView.globalElementIndexPath)
        return config.prototype.systemLayoutSizeFitting(
            target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel).height
    }

    func heightForGlobalFooter(in collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout) -> CGFloat {
        guard let config = (dataSource as? GlobalDataSource)?.globalFooterConfiguration else { return 0 }
        globalConfigurations[UICollectionView.elementKindGlobalFooter] = config

        let width = collectionView.bounds.width
        let target = CGSize(width: width, height: 0)

        config.configure(config.prototype, UICollectionView.globalElementIndexPath)
        return config.prototype.systemLayoutSizeFitting(
            target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel).height
    }

}

extension CollectionViewWrapper {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let (localDataSource, localIndexPath) = self.dataSource.dataSourceFor(global: indexPath)

        guard let dataSource = localDataSource as? DataSource & DataSourceUIProviding else {
            fatalError("The dataSource: (\(String(describing: localDataSource))), must conform to \(String(describing: DataSourceUIProviding.self))")
        }

        let config = dataSource.cellConfiguration(for: localIndexPath)
        cellConfigurations[indexPath] = config

        let metrics = dataSource.metrics(for: localIndexPath.section)
        let size = CGSize(width: collectionView.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let context = DataSourceUISizingContext(prototype: config.prototype, indexPath: localIndexPath, layoutSize: size, metrics: metrics)

        config.configure(config.prototype, localIndexPath)
        return dataSource.sizingStrategy.size(forElementAt: localIndexPath, context: context)
    }

    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let (localDataSource, localIndexPath) = self.dataSource.dataSourceFor(global: indexPath)

        guard let dataSource = localDataSource as? DataSource & DataSourceUIProviding else {
            fatalError("The dataSource: (\(String(describing: localDataSource))), must conform to \(String(describing: DataSourceUIProviding.self))")
        }

        let config = cellConfigurations[indexPath] ?? dataSource.cellConfiguration(for: localIndexPath)
        let type = Swift.type(of: config.prototype)

        switch config.dequeueSource {
        case .nib:
            collectionView.register(nibType: type, reuseIdentifier: config.reuseIdentifier)
        case .class:
            collectionView.register(classType: type, reuseIdentifier: config.reuseIdentifier)
        }

        return collectionView.dequeueReusableCell(withReuseIdentifier: config.reuseIdentifier, for: indexPath)
    }

    internal func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let (localDataSource, localIndexPath) = self.dataSource.dataSourceFor(global: indexPath)

        guard let dataSource = localDataSource as? DataSource & DataSourceUIProviding else {
            fatalError("The dataSource: (\(String(describing: localDataSource))), must conform to \(String(describing: DataSourceUIProviding.self))")
        }

        let config = cellConfigurations[indexPath] ?? dataSource.cellConfiguration(for: localIndexPath)
        config.configure(cell, localIndexPath)

        guard let editable = dataSource as? DataSourceUIEditing, editable.supportsEditing(for: localIndexPath) else { return }
        (cell as? DataSourceUIEditingCell)?.setEditing(editable.isEditing, animated: false)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let (localDataSource, localIndexPath) = self.dataSource.dataSourceFor(global: indexPath)
        guard let dataSource = localDataSource as? DataSourceUISelecting,
            dataSource.supportsSelection(for: localIndexPath) else { return }
        dataSource.selectElement(for: localIndexPath)
        delegate?.collectionView(collectionView, didSelectItem: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let (localDataSource, localIndexPath) = self.dataSource.dataSourceFor(global: indexPath)
        guard let dataSource = localDataSource as? DataSourceUISelecting,
            dataSource.supportsSelection(for: localIndexPath) else { return }
        delegate?.collectionView(collectionView, didDeselectItem: indexPath)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.collectionView(collectionView, didScrollTo: collectionView.contentOffset)
    }

}
