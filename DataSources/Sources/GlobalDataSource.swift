public final class GlobalDataSource<T> {

    let data: T

    public init(data: T) {
        self.data = data
    }

}

public final class RootDataSource<Header, Footer>: DataSource {

    public let child: DataSource
    public var globalHeaderDataSource: GlobalDataSource<Header>?
    public var globalFooterDataSource: GlobalDataSource<Footer>?

    public init(child: DataSource) {
        self.child = child
    }

    public var updateDelegate: DataSourceUpdateDelegate? {
        didSet { child.updateDelegate = updateDelegate }
    }

    public func numberOfElements(in section: Int) -> Int {
        return child.numberOfElements(in: section)
    }

    public func indexPath(where predicate: (Any) -> Bool) -> IndexPath? {
        return child.indexPath(where: predicate)
    }

    public func layoutStrategy(in section: Int) -> FlowLayoutStrategy {
        return child.layoutStrategy(in: section)
    }

    public func cellSource(for indexPath: IndexPath) -> DataSourceViewSource {
        return child.cellSource(for: indexPath)
    }

    public func supplementViewSource(for indexPath: IndexPath, ofKind kind: String) -> DataSourceViewSource {
        return child.supplementViewSource(for: indexPath, ofKind: kind)
    }

    public func prepare(cell: DataSourceCell, at indexPath: IndexPath) {
        child.prepare(cell: cell, at: indexPath)
    }

    public func prepare(supplementaryView: UICollectionReusableView, at indexPath: IndexPath, of kind: String) {
        child.prepare(supplementaryView: supplementaryView, at: indexPath, of: kind)
    }

}
