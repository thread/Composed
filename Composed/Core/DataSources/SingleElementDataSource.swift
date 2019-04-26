/**
 A `DataSource` that contains a single element. This DataSource will always
 return `1` for `numberOfSections`.
 */
open class SingleElementDataSource<Element>: DataSource {

    /// A delegate that will be notified of updates to the data source
    public weak var updateDelegate: DataSourceUpdateDelegate?
    
    /// The element being stored by the data source
    public private(set) var element: Element
    
    /// `true` if `element` is an `Optional.none`
    public var elementIsNil: Bool {
        switch element as Any {
        case Optional<Any>.none: return true
        default: return false
        }
    }

    /// The number of elements the data source provides. Hardcoded to `1`
    public var numberOfSections: Int { return 1 }

    /// The index paths this data source provides. Each `IndexPath` will
    /// have a section of 0
    public var indexPaths: [IndexPath] {
        return (0...numberOfElements(in: 0)).map { IndexPath(item: $0, section: 0) }
    }

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
        
        return elementIsNil ? 0 : 1
    }

    /**
     Set the element stored by the data source and update the delegate as required
     
     - parameter element: The new element
     */
    public func setElement(_ element: Element) {
        let previousIndexPaths = indexPaths

        updateDelegate?.dataSource(self, willPerform: [])
        updateDelegate?.dataSource(self, performBatchUpdates: {
            self.element = element
            let indexPaths = self.indexPaths

            switch (previousIndexPaths.isEmpty, indexPaths.isEmpty) {
            case (false, false):
                let indexPathsDelta = indexPaths.count - previousIndexPaths.count
                if indexPathsDelta == 0 {
                    updateDelegate?.dataSource(self, didUpdateIndexPaths: indexPaths)
                } else {
                    updateDelegate?.dataSourceDidReload(self)
                }
            case (true, false):
                updateDelegate?.dataSource(self, didInsertIndexPaths: indexPaths)
            case (false, true):
                updateDelegate?.dataSource(self, didDeleteIndexPaths: previousIndexPaths)
            case (true, true):
                break
            }
        }, completion: { _ in
            self.updateDelegate?.dataSource(self, didPerform: [])
        })
    }

}
