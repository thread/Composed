import Foundation

public final class ArrayDataStore<Element>: MutableDataStore {

    public weak var dataSource: DataSource?
    public weak var delegate: DataStoreDelegate?
    public private(set) var elements: [Element] = []

    public init(elements: [Element]) {
        self.elements = elements
    }

    public var numberOfSections: Int {
        return 1
    }

    public func numberOfElements(in section: Int) -> Int {
        return elements.count
    }

    public func element(at indexPath: IndexPath) -> Element {
        guard indexPath.section == 0 else {
            fatalError("Invalid section index: \(indexPath.section). Should always be 0")
        }

        return elements[indexPath.item]
    }

    public func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath? {
        if let index = elements.firstIndex(where: predicate) {
            return IndexPath(item: index, section: 0)
        } else {
            return nil
        }
    }

    public func insert(_ element: Element, at index: Int) {
        elements.insert(element, at: index)
        delegate?.dataStore(didInsertIndexPaths: [IndexPath(item: index, section: 0)])
    }

    public func remove(at index: Int) -> Element {
        let element = elements.remove(at: index)
        delegate?.dataStore(didDeleteIndexPaths: [IndexPath(item: index, section: 0)])
        return element
    }

    public func setElements(_ elements: [Element], changesets: [DataSourceChangeset]? = nil) {
        guard let changesets = changesets else {
            self.elements = elements
            delegate?.dataStoreDidReload()
            return
        }

        let updates = changesets.flatMap { $0.updates }

        delegate?.dataStore(performBatchUpdates: {
            self.elements = elements
            delegate?.dataStore(willPerform: updates)

            for changeset in changesets {
                if !changeset.deletedSections.isEmpty {
                    delegate?.dataStore(didDeleteSections: IndexSet(changeset.deletedSections))
                }

                if !changeset.insertedSections.isEmpty {
                    delegate?.dataStore(didInsertSections: IndexSet(changeset.insertedSections))
                }

                if !changeset.updatedSections.isEmpty {
                    delegate?.dataStore(didUpdateSections: IndexSet(changeset.updatedSections))
                }

                for (source, target) in changeset.movedSections {
                    delegate?.dataStore(didMoveSection: source, to: target)
                }

                if !changeset.deletedIndexPaths.isEmpty {
                    delegate?.dataStore(didDeleteIndexPaths: changeset.deletedIndexPaths)
                }

                if !changeset.insertedIndexPaths.isEmpty {
                    delegate?.dataStore(didInsertIndexPaths: changeset.insertedIndexPaths)
                }

                if !changeset.updatedIndexPaths.isEmpty {
                    delegate?.dataStore(didUpdateIndexPaths: changeset.updatedIndexPaths)
                }

                for (source, target) in changeset.movedIndexPaths {
                    delegate?.dataStore(didMoveFromIndexPath: source, toIndexPath: target)
                }
            }
        }, completion: { [weak delegate] _ in
            delegate?.dataStore(didPerform: updates)
        })
    }

}
