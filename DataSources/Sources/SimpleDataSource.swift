open class SimpleDataSource<Element>: CollectionDataSource {

    public weak var updateDelegate: DataSourceUpdateDelegate?
    public private(set) var elements: [Element] = []

    public init(elements: [Element] = []) {
        self.elements = elements
    }

    public func setElements(_ elements: [Element], changeset: DataSourceChangeset? = nil) {
        guard let changeset = changeset else {
            self.elements = elements
            updateDelegate?.dataSourceDidReload(self)
            return
        }

        let updates = changeset.updates

        updateDelegate?.dataSource(self, performBatchUpdates: {
            self.elements = elements
            updateDelegate?.dataSource(self, willPerform: updates)

            if !changeset.deletedSections.isEmpty {
                updateDelegate?.dataSource(self, didDeleteSections: IndexSet(changeset.deletedSections))
            }

            if !changeset.insertedSections.isEmpty {
                updateDelegate?.dataSource(self, didInsertSections: IndexSet(changeset.insertedSections))
            }

            if !changeset.updatedSections.isEmpty {
                updateDelegate?.dataSource(self, didUpdateSections: IndexSet(changeset.updatedSections))
            }

            for (source, target) in changeset.movedSections {
                updateDelegate?.dataSource(self, didMoveSection: source, to: target)
            }

            if !changeset.deletedIndexPaths.isEmpty {
                updateDelegate?.dataSource(self, didDeleteIndexPaths: changeset.deletedIndexPaths)
            }

            if !changeset.insertedIndexPaths.isEmpty {
                updateDelegate?.dataSource(self, didInsertIndexPaths: changeset.insertedIndexPaths)
            }

            if !changeset.updatedIndexPaths.isEmpty {
                updateDelegate?.dataSource(self, didUpdateIndexPaths: changeset.updatedIndexPaths)
            }

            for (source, target) in changeset.movedIndexPaths {
                updateDelegate?.dataSource(self, didMoveFromIndexPath: source, toIndexPath: target)
            }
        }, completion: { [unowned self] _ in
            self.updateDelegate?.dataSource(self, didPerform: updates)
        })
    }

    public func indexPath(where predicate: (Any) -> Bool) -> IndexPath? {
        for (index, element) in elements.enumerated() {
            if predicate(element) { return IndexPath(item: index, section: 0) }
        }

        return nil
    }

    open func cellSource(for indexPath: IndexPath) -> DataSourceViewSource {
        fatalError("Implement in subclass")
    }

    open func supplementViewSource(for indexPath: IndexPath, ofKind kind: String) -> DataSourceViewSource {
        fatalError("Implement in subclass")
    }

    open func layoutStrategy(in section: Int) -> FlowLayoutStrategy {
        fatalError("Implement in subclass")
    }

    open func prepare(cell: DataSourceCell, at indexPath: IndexPath) {
        fatalError("Implement in subclass")
    }

    open func prepare(supplementaryView: UICollectionReusableView, at indexPath: IndexPath, of kind: String) {
        fatalError("Implement in subclass")
    }

}
