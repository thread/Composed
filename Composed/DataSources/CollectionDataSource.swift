public protocol CollectionDataSource: DataSource {
    associatedtype Element

    subscript(indexPath: IndexPath) -> Element { get }
    func element(at indexPath: IndexPath) -> Element

    func setElements(_ elements: [Element], changeset: DataSourceChangeset?)
}

extension CollectionDataSource {
    public var numberOfSections: Int { return 1 }
}

extension SimpleDataSource where Element: Equatable {
    public func indexPath(for element: Element) -> IndexPath? {
        guard let index = elements.index(of: element) else { return nil }
        return IndexPath(item: index, section: 0)
    }
}

extension SimpleDataSource {
    public func numberOfElements(in section: Int) -> Int { return elements.count }
    public var isEmpty: Bool { return elements.isEmpty }
    
    public subscript(indexPath: IndexPath) -> Element { return element(at: indexPath) }
    public func element(at indexPath: IndexPath) -> Element {
        return elements[indexPath.item]
    }
}
