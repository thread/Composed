import Foundation

protocol UpdateDelegate: class {
    func section(_ section: Section, didInsertElementAt index: Int)
    func provider(_ provider: SectionProvider, didInsertSections sections: [Section], at indexes: IndexSet)
}

protocol Section: class {
    var numberOfElements: Int { get }
    var updateDelegate: UpdateDelegate? { get set }
}

extension Section {
    var isEmpty: Bool { return numberOfElements == 0 }
}

protocol MutableSection: Section { }

enum Kind {
    case provider(SectionProvider)
    case section(Section)
}

protocol SectionProvider: class {
    var updateDelegate: UpdateDelegate? { get set }

    var sections: [Section] { get }

    var numberOfSections: Int { get }
    func numberOfElements(in section: Int) -> Int
}

protocol AggregateSectionProvider: SectionProvider {
    var providers: [SectionProvider] { get }
    var cachedProviderSections: [HashableProvider: Int] { get }
}

struct HashableProvider: Hashable {
    let provider: SectionProvider

    init(_ provider: SectionProvider) {
        self.provider = provider
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(provider))
    }

    static func == (lhs: HashableProvider, rhs: HashableProvider) -> Bool {
        return lhs.provider === rhs.provider
    }
}

extension SectionProvider {
    var isEmpty: Bool {
        return sections.allSatisfy { $0.isEmpty }
    }

    var numberOfSections: Int { return sections.count }

    func numberOfElements(in section: Int) -> Int {
        return sections[section].numberOfElements
    }
}

final class ArraySection<Element>: MutableSection {

    weak var updateDelegate: UpdateDelegate?
    var elements: [Element] = []

    func element(at index: Int) -> Element {
        return elements[index]
    }

    var numberOfElements: Int {
        return elements.count
    }

    func append(element: Element) {
        let index = elements.count
        elements.append(element)
        updateDelegate?.section(self, didInsertElementAt: index)
    }
    
}

final class ComposedSectionProvider: AggregateSectionProvider {

    var updateDelegate: UpdateDelegate? {
        didSet {
            providers.forEach { $0.updateDelegate = updateDelegate }
        }
    }

    var cachedProviderSections: [HashableProvider: Int] {
        var offset: Int = 0
        var result = [HashableProvider: Int]()
        result[HashableProvider(self)] = offset

        return children.reduce(into: result) { result, store in
            switch store {
            case .section:
                offset += 1
            case .provider(let provider):
                if let provider = provider as? AggregateSectionProvider {
                    provider.cachedProviderSections.forEach {
                        result[$0.key] = $0.value + offset
                    }
                } else {
                    result[HashableProvider(provider)] = offset
                }

                offset += provider.numberOfSections
            }
        }
    }


    private var children: [Kind] = []

    var sections: [Section] {
        return children.flatMap { kind -> [Section] in
            switch kind {
            case let .section(section):
                return [section]
            case let .provider(provider):
                return provider.sections
            }
        }
    }

    var providers: [SectionProvider] {
        return children.compactMap { kind  in
            switch kind {
            case .section: return nil
            case let .provider(provider):
                return provider
            }
        }
    }

    var numberOfSections: Int {
        return children.reduce(into: 0, { result, kind in
            switch kind {
            case .section: result += 1
            case let .provider(provider): result += provider.numberOfSections
            }
        })
    }

    func numberOfElements(in section: Int) -> Int {
        return sections[section].numberOfElements
    }

    func append(_ child: SectionProvider) {
        child.updateDelegate = updateDelegate

        let firstIndex = sections.count
        let endIndex = firstIndex + child.sections.count

        children.append(.provider(child))
        updateDelegate?.provider(self, didInsertSections: child.sections, at: IndexSet(integersIn: firstIndex..<endIndex))
    }

    func append(_ child: Section) {
        let index = children.count
        children.append(.section(child))
        updateDelegate?.provider(self, didInsertSections: [child], at: IndexSet(integer: index))
    }

}

extension DataSourceCoordinator: UpdateDelegate {

    func provider(_ provider: SectionProvider, didInsertSections sections: [Section], at indexes: IndexSet) {
        if provider !== globalProvider, let globalProvider = globalProvider as? AggregateSectionProvider {
            let firstSection = globalProvider.cachedProviderSections[HashableProvider(provider)]
            let globalIndexes = IndexSet(indexes.map { $0 + firstSection! })
            collectionView.insertSections(globalIndexes)
        } else {
            collectionView.insertSections(indexes)
        }
    }

    func section(_ section: Section, didInsertElementAt index: Int) {
        guard let section = globalProvider.sections.firstIndex(where: { $0 === section }) else { return }
        let indexPath = IndexPath(item: index, section: section)
        collectionView.insertItems(at: [indexPath])
    }

}

open class SectionedDataSource<Element>: CollectionDataSource {

    public typealias Store = ArrayDataStore<Element>
    public private(set) var stores: [ArrayDataStore<Element>] = []

    public weak var updateDelegate: DataSourceUpdateDelegate?

    public init(stores: [ArrayDataStore<Element>] = []) {
        self.stores = stores
    }

    public init(elements: [Element]) {
        stores = [ArrayDataStore(elements: elements)]
    }

    public convenience init(stores: ArrayDataStore<Element>...) {
        self.init(stores: stores)
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
        return stores[section].numberOfElements(in: 0)

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

    public func localSection(for section: Int) -> (dataSource: DataSource, localSection: Int) {
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

        var details = ComposedChangeDetails()
        details.insertedSections = IndexSet(integer: stores.count)
        updateDelegate?.dataSource(self, performUpdates: details)
    }

    func insert(store: Store, at index: Int) {
        store.delegate = self
        stores.insert(store, at: index)

        var details = ComposedChangeDetails()
        details.insertedSections = IndexSet(integer: index)
        updateDelegate?.dataSource(self, performUpdates: details)
    }

    func remove(store: Store) {
        guard let index = stores.firstIndex(where: { $0 === store }) else { return }
        store.delegate = nil
        stores.remove(at: index)

        var details = ComposedChangeDetails()
        details.removedSections = IndexSet(integer: index)
        updateDelegate?.dataSource(self, performUpdates: details)
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
