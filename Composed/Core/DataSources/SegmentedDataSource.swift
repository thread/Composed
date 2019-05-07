import Foundation

public protocol DataSourceUpdateDelegateSegmented: DataSourceUpdateDelegate {
    func dataSource(_ dataSource: SegmentedDataSource, didSelect child: DataSource, atIndex index: Int)
}

open class SegmentedDataSource: AggregateDataSource {

    public var descendants: [DataSource] {
        guard let child = selectedChild else { return [] }
        if let aggregate = child as? AggregateDataSource {
            return [child] + aggregate.descendants
        } else {
            return [child]
        }
    }

    public var children: [DataSource] {
        guard let child = selectedChild else {
            return []
        }

        return [child]
    }

    private var _children: [DataSource] = []

    public var numberOfSections: Int {
        return selectedChild?.numberOfSections ?? 0
    }

    public weak var updateDelegate: DataSourceUpdateDelegate?
    public private(set) var selectedChild: DataSource?

    public var selectedIndex: Int {
        guard let child = selectedChild,
            let index = _children.firstIndex(where: { $0 === child }) else {
                return -1
        }

        return index
    }

    public init() { }
    public init(children: [DataSource]) {
        children.forEach { append(dataSource: $0) }
    }

    public final func setSelected(index: Int?, animated: Bool = false) {
        guard index != selectedIndex else { return }

        guard let index = index else {
            selectedChild = nil

            if animated {
                updateDelegate?.dataSource(self, didDeleteSections: IndexSet(integer: 0))
            } else {
                updateDelegate?.dataSourceDidReload(self)
            }

            return
        }
        
        guard _children.indices.contains(index) else {
            assertionFailure("Index out of bounds: \(index). Should be in the range: \(0..<_children.count)")
            return
        }

        let deletedSections = 0..<numberOfSections
        let insertedSections = 0..<_children[index].numberOfSections

        selectedChild = _children[index]

        if animated {
            updateDelegate?.dataSource(self, performBatchUpdates: {
                updateDelegate?.dataSource(self, didDeleteSections: IndexSet(deletedSections))
                updateDelegate?.dataSource(self, didInsertSections: IndexSet(insertedSections))
            }, completion: nil)
        } else {
            updateDelegate?.dataSourceDidReload(self)
        }

        (updateDelegate as? DataSourceUpdateDelegateSegmented)?
            .dataSource(self, didSelect: _children[index], atIndex: index)
    }

    public final func append(dataSource: DataSource) {
        insert(dataSource: dataSource, at: _children.count)
    }

    public final func insert(dataSource: DataSource, at index: Int) {
        _children.insert(dataSource, at: index)

        if selectedChild == nil {
            setSelected(index: index, animated: false)
        }

        dataSource.updateDelegate = self
    }

    public final func remove(dataSource: DataSource) {
        guard let index = _children.firstIndex(where: { $0 === dataSource }) else {
            fatalError("DataSource is not a child of this DataSource")
        }

        _children.remove(at: index)
        dataSource.updateDelegate = nil

        if _children.isEmpty {
            setSelected(index: nil, animated: true)
        } else {
            setSelected(index: _children.index(before: index), animated: true)
        }
    }

    public final func removeAll() {
        _children.forEach { $0.updateDelegate = nil }
        _children.removeAll()
        setSelected(index: nil, animated: true)
    }

    public final func numberOfElements(in section: Int) -> Int {
        return selectedChild?.numberOfElements(in: section) ?? 0
    }

    public final func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath? {
        return selectedChild?.indexPath(where: predicate)
    }

    public final func localSection(for section: Int) -> (dataSource: DataSource, localSection: Int) {
        guard let child = selectedChild else { fatalError("SegmentedDataSource has no selectedChild") }
        return child.localSection(for: section)
    }

    open func prepare() {
        children
            .lazy
            .compactMap { $0 as? LifecycleObservingDataSource }
            .forEach { $0.prepare() }
    }

    open func invalidate() {
        children
            .lazy
            .compactMap { $0 as? LifecycleObservingDataSource }
            .forEach { $0.invalidate() }
    }

    open func didBecomeActive() {
        (selectedChild as? LifecycleObservingDataSource)?.didBecomeActive()
    }

    open func willResignActive() {
        (selectedChild as? LifecycleObservingDataSource)?.willResignActive()
    }

}

extension SegmentedDataSource: DataSourceUpdateDelegate {

    public final func dataSource(_ dataSource: DataSource, willPerform updates: [DataSourceUpdate]) {
        guard selectedChild != nil else { return }
        updateDelegate?.dataSource(self, willPerform: updates)
    }

    public final func dataSource(_ dataSource: DataSource, didPerform updates: [DataSourceUpdate]) {
        guard selectedChild != nil else { return }
        updateDelegate?.dataSource(self, didPerform: updates)
    }

    public final func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet) {
        guard selectedChild != nil else { return }
        updateDelegate?.dataSource(self, didInsertSections: sections)
    }

    public final func dataSource(_ dataSource: DataSource, didDeleteSections sections: IndexSet) {
        guard selectedChild != nil else { return }
        updateDelegate?.dataSource(self, didDeleteSections: sections)
    }

    public final func dataSource(_ dataSource: DataSource, didUpdateSections sections: IndexSet) {
        guard selectedChild != nil else { return }
        updateDelegate?.dataSource(self, didUpdateSections: sections)
    }

    public final func dataSource(_ dataSource: DataSource, didMoveSection from: Int, to: Int) {
        guard selectedChild != nil else { return }
        updateDelegate?.dataSource(self, didMoveSection: from, to: to)
    }

    public final func dataSource(_ dataSource: DataSource, didInsertIndexPaths indexPaths: [IndexPath]) {
        guard selectedChild != nil else { return }
        updateDelegate?.dataSource(self, didInsertIndexPaths: indexPaths)
    }

    public final func dataSource(_ dataSource: DataSource, didDeleteIndexPaths indexPaths: [IndexPath]) {
        guard selectedChild != nil else { return }
        updateDelegate?.dataSource(self, didDeleteIndexPaths: indexPaths)
    }

    public final func dataSource(_ dataSource: DataSource, didUpdateIndexPaths indexPaths: [IndexPath]) {
        guard selectedChild != nil else { return }
        updateDelegate?.dataSource(self, didUpdateIndexPaths: indexPaths)
    }

    public final func dataSource(_ dataSource: DataSource, didMoveFromIndexPath from: IndexPath, toIndexPath to: IndexPath) {
        guard selectedChild != nil else { return }
        updateDelegate?.dataSource(self, didMoveFromIndexPath: from, toIndexPath: to)
    }

    public final func dataSourceDidReload(_ dataSource: DataSource) {
        guard selectedChild != nil else { return }
        updateDelegate?.dataSourceDidReload(self)
    }

    public final func dataSource(_ dataSource: DataSource, performBatchUpdates updates: () -> Void, completion: ((Bool) -> Void)?) {
        guard selectedChild != nil else { return }
        updateDelegate?.dataSource(self, performBatchUpdates: updates, completion: completion)
    }

    public final func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceInvalidationContext) {
        guard selectedChild != nil else { return }
        updateDelegate?.dataSource(self, invalidateWith: context)
    }

    public func dataSource(_ dataSource: DataSource, sectionFor local: Int) -> (dataSource: DataSource, globalSection: Int) {
        guard selectedChild != nil else { return (self, local) }
        return updateDelegate?.dataSource(self, sectionFor: local) ?? (self, local)
    }

}
