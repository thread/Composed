public protocol DataReusableView: class {
    static var reuseIdentifier: String { get }
}

public extension DataReusableView {
    static var reuseIdentifier: String { return String(describing: self) }
}

extension UICollectionReusableView: DataReusableView {
    public func systemLayoutSize(inLayout strategy: FlowLayoutStrategy) -> CGSize {
        return sizeThatFits(.zero)
    }
}

private extension UICollectionView {
    func register(nibType: DataReusableView.Type, kind: String? = nil) {
        let nib = UINib(nibName: String(describing: nibType), bundle: Bundle(for: nibType))

        if let kind = kind {
            register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: nibType.reuseIdentifier)
        } else {
            register(nib, forCellWithReuseIdentifier: nibType.reuseIdentifier)
        }
    }
}

internal final class CollectionViewWrapper: NSObject, UICollectionViewDataSource, FlowLayoutDelegate {

    internal let collectionView: UICollectionView
    internal let dataSource: DataSource

    private var layoutStrategies: [Int: FlowLayoutStrategy] = [:]

    internal init(collectionView: UICollectionView, dataSource: DataSource) {
        self.collectionView = collectionView
        self.dataSource = dataSource

        super.init()

        collectionView.delegate = self
        collectionView.dataSource = self
    }

    private func layoutStrategy(in section: Int) -> FlowLayoutStrategy {
        if let strategy = layoutStrategies[section] { return strategy }
        let strategy = dataSource.layoutStrategy(in: section)
        layoutStrategies[section] = strategy
        return strategy
    }

    internal func invalidateAll() {
        layoutStrategies.removeAll()
    }

    @objc internal func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSections
    }

    @objc public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfElements(in: section)
    }

    @objc internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch dataSource.cellSource(for: indexPath) {
        case let .nib(type):
            collectionView.register(nibType: type)
            return collectionView.dequeueReusableCell(withReuseIdentifier: type.reuseIdentifier, for: indexPath)
        case let .class(type):
            collectionView.register(type, forCellWithReuseIdentifier: type.reuseIdentifier)
            return collectionView.dequeueReusableCell(withReuseIdentifier: type.reuseIdentifier, for: indexPath)
        }
    }

    @objc internal func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        dataSource.prepare(cell: cell as! DataSourceCell, at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        let strategy = layoutStrategy(in: indexPath.section)
        let prototype = strategy.prototypeCell(for: indexPath)
        dataSource.prepare(cell: prototype, at: indexPath)
        return strategy.size(forCell: prototype, at: indexPath, in: layout)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return layoutStrategy(in: section).insets(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource.layoutStrategy(in: section).horizontalSpacing(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return layoutStrategy(in: section).verticalSpacing(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return layoutStrategy(in: section).headerStrategy?.headerSize(in: section, in: collectionViewLayout) ?? .zero
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch dataSource.supplementViewSource(for: indexPath, ofKind: kind) {
        case let .nib(type):
            collectionView.register(nibType: type.self, kind: kind)
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: type.reuseIdentifier, for: indexPath)
        case let .class(type):
            collectionView.register(type, forSupplementaryViewOfKind: kind, withReuseIdentifier: type.reuseIdentifier)
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: type.reuseIdentifier, for: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        dataSource.prepare(supplementaryView: view, at: indexPath, of: elementKind)
    }

}
