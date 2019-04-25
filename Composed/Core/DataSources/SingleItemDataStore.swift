/**
 A `DataSource` that contains a single item. It is backed by a `SingleItemDataStore`
 */
open class SingleElementDataSource<Element>: DataSource {

    public weak var updateDelegate: DataSourceUpdateDelegate?
    public private(set) var element: Element

    public var numberOfSections: Int { return 1 }

    public var indexPath: IndexPath? {
        return isEmpty ? nil : IndexPath(item: 0, section: 0)
    }

    public var isEmpty: Bool {
        return numberOfElements(in: 0) > 0
    }

    /**
     Create a new `SingleItemDataSource` with the provided element

     - parameter element: The element to populate the backing store with
     */
    public init(element: Element) {
        self.element = element
    }

    public func numberOfElements(in section: Int) -> Int {
        let any = element as Any

        switch any {
        case Optional<Any>.none: return 0
        default: return 1
        }
    }

    public func setElement(_ element: Element) {
        let wasEmpty = isEmpty

        updateDelegate?.dataSource(self, willPerform: [])
        updateDelegate?.dataSource(self, performBatchUpdates: {
            self.element = element
            let indexPath = IndexPath(item: 0, section: 0)

            switch (wasEmpty, isEmpty) {
            case (true, true):
                updateDelegate?.dataSource(self, didUpdateIndexPaths: [indexPath])
            case (true, false):
                updateDelegate?.dataSource(self, didDeleteIndexPaths: [indexPath])
            case (false, true):
                updateDelegate?.dataSource(self, didInsertIndexPaths: [indexPath])
            case (false, false): break
            }
        }, completion: { _ in
            self.updateDelegate?.dataSource(self, didPerform: [])
        })
    }

}
