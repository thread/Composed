import Foundation

open class SectionedDataSource<Element>: CollectionDataSource {

    public typealias Store = ArrayDataStore<Element>
    public private(set) var stores: [ArrayDataStore<Element>] = []

    public weak var updateDelegate: DataSourceUpdateDelegate?

    public init(stores: [ArrayDataStore<Element>] = []) {
        self.stores = stores
    }

    public init(elements: [Element]) {
        if elements.isEmpty { return }
        stores = [ArrayDataStore(elements: elements)]
    }

    public convenience init(elements: Element...) {
        self.init(elements: elements)
    }

    public init(contentsOf elements: [[Element]]) {
        if elements.isEmpty { return }

        stores = elements
            .lazy
            .filter { !$0.isEmpty }
            .map { ArrayDataStore(elements: $0) }
    }

    public var numberOfSections: Int {
        return stores.count
    }

    public func numberOfElements(in section: Int) -> Int {
        return stores[section].numberOfElements(in: section)

    }

    public func element(at indexPath: IndexPath) -> Element {
        let localIndexPath = IndexPath(item: indexPath.item, section: 0)
        return stores[indexPath.section].element(at: localIndexPath)
    }

    public func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath? {
        for section in 0..<stores.count {
            if let indexPath = stores[section].indexPath(where: predicate) {
                return IndexPath(item: indexPath.item, section: section)
            }
        }

        return nil
    }

    public func dataSourceFor(global section: Int) -> (dataSource: DataSource, localSection: Int) {
        return (self, section)
    }

    public func dataSourceFor(global indexPath: IndexPath) -> (dataSource: DataSource, localIndexPath: IndexPath) {
        return (self, indexPath)
    }

}

public extension SectionedDataSource {

    func append(store: Store) {
        store.delegate = self
        stores.append(store)
        updateDelegate?.dataSource(self, didInsertSections: IndexSet(integer: stores.count))
    }

    func insert(store: Store, at index: Int) {
        store.delegate = self
        stores.insert(store, at: index)
        updateDelegate?.dataSource(self, didInsertSections: IndexSet(integer: index))
    }

    func remove(store: Store) {
        guard let index = stores.firstIndex(where: { $0 === store }) else { return }
        store.delegate = nil
        stores.remove(at: index)
        updateDelegate?.dataSource(self, didDeleteSections: IndexSet(integer: index))
    }

}

public extension SectionedDataSource {

    func append(elements: [Element]) {
        guard !elements.isEmpty else { return }
        self.append(store: ArrayDataStore(elements: elements))
    }

    func append(elements: Element...) {
        guard !elements.isEmpty else { return }
        self.append(elements: elements)
    }

    func insert(elements: [Element], at index: Int) {
        guard !elements.isEmpty else { return }
        self.insert(store: ArrayDataStore(elements: elements), at: index)
    }

    func insert(elements: Element..., at index: Int) {
        guard !elements.isEmpty else { return }
        self.insert(store: ArrayDataStore(elements: elements), at: index)
    }

}

extension SectionedDataSource: DataSourceLifecycleObserving where Element: DataSourceLifecycleObserving {

    public func prepare() {
        stores.flatMap { $0.elements }.forEach { $0.prepare() }
    }

    public func invalidate() {
        stores.flatMap { $0.elements }.forEach { $0.invalidate() }
    }

    public func didBecomeActive() {
        stores.flatMap { $0.elements }.forEach { $0.didBecomeActive() }
    }

    public func willResignActive() {
        stores.flatMap { $0.elements }.forEach { $0.willResignActive() }
    }

}
