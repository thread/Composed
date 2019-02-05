public protocol DataStoreDelegate: class {
    func dataStore(willPerform updates: [DataSourceUpdate])
    func dataStore(didPerform updates: [DataSourceUpdate])

    func dataStore(didInsertSections sections: IndexSet)
    func dataStore(didDeleteSections sections: IndexSet)
    func dataStore(didUpdateSections sections: IndexSet)
    func dataStore(didMoveSection from: Int, to: Int)

    func dataStore(didInsertIndexPaths indexPaths: [IndexPath])
    func dataStore(didDeleteIndexPaths indexPaths: [IndexPath])
    func dataStore(didUpdateIndexPaths indexPaths: [IndexPath])
    func dataStore(didMoveFromIndexPath from: IndexPath, toIndexPath to: IndexPath)

    func dataStoreDidReload()
    func dataStore(performBatchUpdates updates: () -> Void, completion: ((Bool) -> Void)?)
}

public protocol DataStore {
    associatedtype Element

    var delegate: DataStoreDelegate? { get set }

    var isEmpty: Bool { get }
    var numberOfSections: Int { get }
    func numberOfElements(in section: Int) -> Int

    func element(at indexPath: IndexPath) -> Element
    func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath?
}

public extension DataStore {

    var isEmpty: Bool {
        return (0..<numberOfSections)
            .lazy
            .allSatisfy { numberOfElements(in: $0) == 0 }
    }

    subscript(indexPath: IndexPath) -> Element {
        return element(at: indexPath)
    }

}

public extension DataStore where Element: Equatable {

    subscript(indexPath: IndexPath) -> Element {
        return element(at: indexPath)
    }

    func indexPath(for element: Element) -> IndexPath? {
        return indexPath { other in
            guard let other = other as? Element else { return false }
            return other == element
        }
    }

}

public struct ArrayStore<Element>: DataStore {

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
        if let index = elements.index(where: predicate) {
            return IndexPath(item: index, section: 0)
        } else {
            return nil
        }
    }

    public mutating func setElements(_ elements: [Element], changeset: DataSourceChangeset? = nil) {
        guard let changeset = changeset else {
            self.elements = elements
            delegate?.dataStoreDidReload()
            return
        }

        let updates = changeset.updates

        delegate?.dataStore(performBatchUpdates: {
            self.elements = elements
            delegate?.dataStore(willPerform: updates)

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
        }, completion: { [weak delegate] _ in
            delegate?.dataStore(didPerform: updates)
        })
    }

}
