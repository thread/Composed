public final class GlobalDataSource: DataSource {

    public let child: DataSource
    public var globalHeaderConfiguration: HeaderFooterConfiguration?
    public var globalFooterConfiguration: HeaderFooterConfiguration?

    public init(child: DataSource) {
        self.child = child
    }

    public var updateDelegate: DataSourceUpdateDelegate? {
        didSet { child.updateDelegate = updateDelegate }
    }

    public var numberOfSections: Int {
        return child.numberOfSections
    }

    public func numberOfElements(in section: Int) -> Int {
        return child.numberOfElements(in: section)
    }

    public func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath? {
        return child.indexPath(where: predicate)
    }

    public func dataSourceFor(global section: Int) -> (dataSource: DataSource, localSection: Int) {
        return (child, section)
    }

    public func dataSourceFor(global indexPath: IndexPath) -> (dataSource: DataSource, localIndexPath: IndexPath) {
        return (child, indexPath)
    }

    public var isEmpty: Bool {
        return child.isEmpty
    }

    public func didBecomeActive() {
        child.didBecomeActive()
    }

    public func willResignActive() {
        child.willResignActive()
    }

    public func invalidate() {
        child.invalidate()
    }

}
