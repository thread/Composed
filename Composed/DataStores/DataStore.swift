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

public protocol DataStore: class {
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
