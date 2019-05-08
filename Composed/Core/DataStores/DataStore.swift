import Foundation

public protocol DataStoreDelegate: class {
    func dataStoreDidUpdate(changeDetails: ComposedChangeDetails)
}

public protocol DataStore: class {
    associatedtype Element

    var delegate: DataStoreDelegate? { get set }

    var isEmpty: Bool { get }
    var numberOfSections: Int { get }
    func numberOfElements(in section: Int) -> Int

    func element(at indexPath: IndexPath) -> Element
    func indexPath(where predicate: @escaping (Element) -> Bool) -> IndexPath?
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
            return other == element
        }
    }

}
