/**
 A `DataSource` that contains a single item. It is backed by a `SingleItemDataStore`
 */
open class SingleItemDataSource<Element>: BasicDataSource<SingleItemDataStore<Element>> {
    
    /**
     Create a new `SingleItemDataSource` with the provided element
     
     - parameter element: The element to populate the backing store with
     */
    public init(element: Element) {
        let store = SingleItemDataStore(element: element)
        super.init(store: store)
    }
    
}
