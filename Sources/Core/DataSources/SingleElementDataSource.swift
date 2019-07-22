import Foundation

/**
 A `DataSource` that contains a single element. This DataSource will always
 return `1` for `numberOfSections`.
 */
open class SingleElementDataSource<Element>: DataSource {

    /// A delegate that will be notified of updates to the data source
    public weak var updateDelegate: DataSourceUpdateDelegate?
    
    /// The element being stored by the data source
    public private(set) var element: Element

    /// The number of elements the data source provides. Hardcoded to `1`
    public var numberOfSections: Int { return 1 }

    public var isEmpty: Bool {
        return numberOfElements(in: 0) == 0
    }

    /**
     Create a new `SingleElementDataSource` with the provided element

     - parameter element: The element to populate the data source store with
     */
    public init(element: Element) {
        self.element = element
    }

    /**
     Returns the number of elements in the provided section.
     
     This data source only supports the first section (section zero) and
     will throw an assertion failure if another section number is passed
     
     By default this will return 0 is `element` is `nil`, otherwise it will
     return 1
     
     This function may be overriden by subclasses to return values other than
     0 and 1, for example if the presence of `element` means more than 1 visual
     element is available
     
     - parameter section: An index number identifying the section. This index value is 0-based.
     - returns: The number of elements in `section`
     */
    open func numberOfElements(in section: Int) -> Int {
        guard section == 0 else {
            assertionFailure(#function + " should not be called with a section other than 0")
            return 0
        }
        
        switch element as Any {
        case Optional<Any>.none: return 0
        default: return 1
        }
    }

    /**
     Set the element stored by the data source and update the delegate as required
     
     - parameter element: The new element
     */
    public func replaceElement(_ element: Element) {
        let wasEmpty = isEmpty
        self.element = element

        var details = ComposedChangeDetails()
        let indexPath = IndexPath(item: 0, section: 0)

        switch (wasEmpty, isEmpty) {
        case (true, true):
            break
        case (true, false):
            details.insertedIndexPaths = [indexPath]
        case (false, true):
            details.removedIndexPaths = [indexPath]
        case (false, false):
            details.updatedIndexPaths = [indexPath]
        }

        updateDelegate?.dataSource(self, performUpdates: details)
    }

    public func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath? {
        if isEmpty { return nil }
        return predicate(element) ? IndexPath(item: 0, section: 0) : nil
    }

    public func localSection(for section: Int) -> (dataSource: DataSource, localSection: Int) {
        return (self, section)
    }

    func dataSource(_ dataSource: DataSource, sectionFor localSection: Int) -> (dataSource: DataSource, globalSection: Int) {
        return (self, localSection)
    }

}
