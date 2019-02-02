public protocol DataReusableView: class {
    static var reuseIdentifier: String { get }
}

public extension DataReusableView {
    static var reuseIdentifier: String { return String(describing: self) }
}

extension UICollectionReusableView: DataReusableView { }

private extension UICollectionView {
    func register(nibType: DataReusableView.Type, kind: String? = nil) {
        let nib = UINib(nibName: String(describing: nibType), bundle: Bundle(for: nibType))

        if let kind = kind {
            register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: nibType.reuseIdentifier)
        } else {
            register(nib, forCellWithReuseIdentifier: nibType.reuseIdentifier)
        }
    }

    func register(classType: DataReusableView.Type, kind: String? = nil) {
        if let kind = kind {
            register(classType, forSupplementaryViewOfKind: kind, withReuseIdentifier: classType.reuseIdentifier)
        } else {
            register(classType, forCellWithReuseIdentifier: classType.reuseIdentifier)
        }
    }
}

internal final class CollectionViewWrapper: NSObject, UICollectionViewDataSource, FlowLayoutDelegate {

    internal let collectionView: UICollectionView
    internal let dataSource: DataSource

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

}

extension CollectionViewWrapper {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return dataSource.metrics(for: section).insets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource.metrics(for: section).horizontalSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource.metrics(for: section).verticalSpacing
    }

}

extension CollectionViewWrapper {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let config = dataSource.headerConfiguration(for: section) else { return .zero }
        let width = collectionView.bounds.width
        let target = CGSize(width: width, height: 0)
        config.configure(config.prototype, section)
        return config.prototype.systemLayoutSizeFitting(
            target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let config = dataSource.footerConfiguration(for: section) else { return .zero }
        let width = collectionView.bounds.width
        let target = CGSize(width: width, height: 0)
        config.configure(config.prototype, section)
        return config.prototype.systemLayoutSizeFitting(
            target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let configuration: HeaderFooterConfiguration?

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            configuration = dataSource.headerConfiguration(for: indexPath.section)
        case UICollectionView.elementKindSectionFooter:
            configuration = dataSource.footerConfiguration(for: indexPath.section)
        default: fatalError("Unsupported")
        }

        guard let config = configuration else { fatalError() }

        let type = Swift.type(of: config.prototype)
        switch config.dequeueSource {
        case .nib:
            collectionView.register(nibType: type, kind: kind)
        case .class:
            collectionView.register(classType: type, kind: kind)
        }

        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: type.reuseIdentifier, for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            let config = dataSource.headerConfiguration(for: indexPath.section)
            config?.configure(view, indexPath.section)
        case UICollectionView.elementKindSectionFooter:
            let config = dataSource.footerConfiguration(for: indexPath.section)
            config?.configure(view, indexPath.section)
        default:
            break
        }
    }

}

extension CollectionViewWrapper {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let metrics = dataSource.metrics(for: indexPath.section)
        let interitemSpacing = CGFloat(metrics.columnCount - 1) * metrics.horizontalSpacing
        let availableWidth = collectionView.bounds.width - metrics.insets.left - metrics.insets.right - interitemSpacing
        let width = (availableWidth / CGFloat(metrics.columnCount)).rounded(.down)
        let target = CGSize(width: width, height: 0)
        let config = dataSource.cellConfiguration(for: indexPath)
        config.configure(config.prototype, indexPath)
        return config.prototype.systemLayoutSizeFitting(
            target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
    }

    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let config = dataSource.cellConfiguration(for: indexPath)
        let type = Swift.type(of: config.prototype)

        switch config.dequeueSource {
        case .nib:
            collectionView.register(nibType: type)
        case .class:
            collectionView.register(classType: type)
        }

        return collectionView.dequeueReusableCell(withReuseIdentifier: type.reuseIdentifier, for: indexPath)
    }

    internal func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? DataSourceCell else { return }
        let config = dataSource.cellConfiguration(for: indexPath)
        config.configure(cell, indexPath)
    }

}
