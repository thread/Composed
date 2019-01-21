//public final class SingleElementDataSource<Element>: DataSource {
//
//    public let element: Element
//
//    public var updateDelegate: DataSourceUpdateDelegate?
//
//    public init(element: Element) {
//        self.element = element
//    }
//
//    public func numberOfElements(inSection section: Int) -> Int {
//        return 1
//    }
//
//    public func indexPath(where predicate: (Any) -> Bool) -> IndexPath? {
//        guard predicate(element) == true else { return nil }
//        return IndexPath(item: 0, section: 0)
//    }
//
//    public func localIndexPath(forGlobal indexPath: IndexPath) -> IndexPath? {
//        return IndexPath(item: 0, section: 0)
//    }
//
//    public func viewType(for indexPath: IndexPath, ofKind kind: String?) -> DataReusableView.Type {
//        fatalError()
//    }
//
//    public func layoutStrategy(for section: Int) -> FlowLayoutStrategy {
//        fatalError()
//    }
//
//    public func prepare(cell: DataSourceCell, at indexPath: IndexPath) {
//        fatalError()
//    }
//
//}

public protocol CollectionDataSource: DataSource {
    associatedtype Element
    var elements: [Element] { get }

    subscript(indexPath: IndexPath) -> Element? { get }
    func element(at indexPath: IndexPath) -> Element?

    func setElements(_ elements: [Element], changeset: DataSourceChangeset?)
}

extension CollectionDataSource {
    public var isEmpty: Bool { return elements.isEmpty }
    public var numberOfSections: Int { return 1 }
    public func numberOfElements(inSection section: Int) -> Int { return elements.count }
}

extension CollectionDataSource where Element: Equatable {
    public func indexPath(for element: Element) -> IndexPath? {
        guard let index = elements.index(of: element) else { return nil }
        return IndexPath(item: index, section: 0)
    }
}

extension CollectionDataSource {
    public subscript(indexPath: IndexPath) -> Element? { return element(at: indexPath) }
    public func element(at indexPath: IndexPath) -> Element? {
        guard elements.indices.contains(indexPath.section) else { return nil }
        return elements[indexPath.item]
    }
}
