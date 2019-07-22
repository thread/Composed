/**
 A `BasicDataSource` subclass that uses the `ArrayDataStore`, allowing for
 the storage of an array of `Elements`.
 */
open class ArrayDataSource<Element>: BasicDataSource<ArrayDataStore<Element>> {
    
    /**
     Create a new `ArrayDataSource` with the provided elements
     
     - parameter elements: The elements to passed to the `ArrayDataStore`
     */
    public convenience init(elements: [Element]) {
        let store = ArrayDataStore(elements: elements)
        self.init(store: store)
    }
    
}
