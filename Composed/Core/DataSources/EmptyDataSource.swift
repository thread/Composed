import Foundation

open class EmptyDataSource: DataSource {
    public var isEmpty: Bool { return true }
    public weak var updateDelegate: DataSourceUpdateDelegate?
    public var numberOfSections: Int { return 1 }
    public func numberOfElements(in section: Int) -> Int { return 0 }
    public func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath? { return nil }
    public func localSection(for section: Int) -> (dataSource: DataSource, localSection: Int) { return (self, section) }
    public init() { }
}
