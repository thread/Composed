import Foundation

public protocol LifecycleObservingDataSource: DataSource {

    /// Called when the dataSource is initially prepared, or after an invalidation.
    func prepare()

    /// Called when the dataSource has been invalidated, generally when the dataSource has been removed
    func invalidate()

    /// Called whenever the dataSource becomes active, after being inactive
    func didBecomeActive()

    /// Called whenever the dataSource resigns active, after being active
    func willResignActive()

}

extension LifecycleObservingDataSource where Self: CollectionDataSource {
    public func prepare() { }
    public func invalidate() { }
    public func didBecomeActive() { }
    public func willResignActive() { }
}
