import Foundation

/**
 A `DataStore` that contains a single element of type `Element`
 */
open class SingleItemDataStore<Element>: DataStore {
    
    public let element: Element
    
    public weak var delegate: DataStoreDelegate?
    
    public weak var dataSource: Composed.DataSource?
    
    public let numberOfSections: Int = 1
    
    /**
     Create a new `SingleItemDataStore` with the provided element
     
     - parameter element: The element to populate the store with
     */
    public init(element: Element) {
        self.element = element
    }
    
    public func numberOfElements(in section: Int) -> Int {
        return 1
    }
    
    public func element(at indexPath: IndexPath) -> Element {
        guard indexPath.item == 0 else { fatalError() }
        return element
    }
    
    public func indexPath(where predicate: @escaping (Element) -> Bool) -> IndexPath? {
        return predicate(element) ? IndexPath(item: 0, section: 0) : nil
    }
    
}
