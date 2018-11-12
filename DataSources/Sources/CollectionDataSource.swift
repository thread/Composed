public protocol CollectionDataSource: DataSource {
    associatedtype Element
    var elements: [Element] { get }

    subscript(indexPath: IndexPath) -> Element? { get }
    func element(at indexPath: IndexPath) -> Element?

    func setElements(_ elements: [Element], changesets: [DataSourceChangeset])
}

extension CollectionDataSource {
    public var isEmpty: Bool { return elements.isEmpty }
    public var numberOfSections: Int { return 1 }
    public func numberOfItems(inSection section: Int) -> Int { return elements.count }
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
