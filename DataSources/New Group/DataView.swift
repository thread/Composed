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

extension UICollectionView {
    public func register(nibType: DataReusableView.Type, kind: String? = nil) {
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
        return dataSource.numberOfElements(inSection: section)
    }

    @objc internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellType = dataSource.cellType(for: indexPath)
        collectionView.register(nibType: cellType.self)
        return collectionView.dequeueReusableCell(withReuseIdentifier: cellType.reuseIdentifier, for: indexPath)
    }

    @objc internal func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        dataSource.prepare(cell: cell as! DataSourceCell, at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        return dataSource.layoutStrategy(for: indexPath.section).cellSize(for: indexPath, in: layout)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return dataSource.layoutStrategy(for: section).insets(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource.layoutStrategy(for: section).horizontalSpacing(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource.layoutStrategy(for: section).verticalSpacing(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return dataSource.layoutStrategy(for: section).headerStrategy?.headerSize(in: section, in: collectionViewLayout) ?? .zero
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let supplementaryType = dataSource.supplementType(for: indexPath, ofKind: kind)
        collectionView.register(nibType: supplementaryType.self, kind: kind)
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: supplementaryType.reuseIdentifier, for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        dataSource.prepare(supplementaryView: view, at: indexPath, of: elementKind)
    }

}
