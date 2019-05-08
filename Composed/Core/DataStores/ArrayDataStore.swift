import Foundation

public final class ArrayDataStore<Element>: DataStore {

    public weak var dataSource: DataSource?
    public weak var delegate: DataStoreDelegate?
    public internal(set) var elements: [Element] = []

    public var isEmpty: Bool {
        return elements.isEmpty
    }

    public init() {
        self.elements = []
    }

    public convenience init(elements: [Element]) {
        self.init()
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

}

extension ArrayDataStore {

    @available(*, deprecated, renamed: "replaceElements(_:changesets:)")
    public func setElements(_ elements: [Element], changesets: [DataSourceChangeset]? = nil) {
        replaceElements(elements, changesets: changesets)
    }

}
