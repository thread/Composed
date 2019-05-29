import Foundation

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
        return selectedChild.flatMap { [$0] } ?? []
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
        if index == nil && selectedChild == nil { return }
        
        var details = ComposedChangeDetails(hasIncrementalChanges: animated)

        defer {
            updateDelegate?.dataSource(self, performUpdates: details)
        }

        let newIndex = index
        let index: Int? = selectedChild == nil ? nil : selectedIndex

        switch (index, newIndex) {
        case let (.some(index), .none):
            selectedChild?.updateDelegate = nil
            selectedChild = nil
            details.removedSections = IndexSet(integer: index)
        case let (.none, .some(newIndex)):
            guard _children.indices.contains(newIndex) else {
                assertionFailure("Index out of bounds: \(newIndex). Should be in the range: \(0..<_children.count)")
                return
            }

            selectedChild = _children[newIndex]
            details.insertedSections = IndexSet(integer: newIndex)
            selectedChild?.updateDelegate = self
        case let (.some, .some(newIndex)):
            details.updatedSections = IndexSet(integer: newIndex)
        case (.none, .none):
            break
        }
    }

    public final func append(dataSource: DataSource) {
        insert(dataSource: dataSource, at: _children.count)
    }

    public final func insert(dataSource: DataSource, at index: Int) {
        _children.insert(dataSource, at: index)

        if selectedChild == nil {
            setSelected(index: index, animated: false)
        }
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

}

extension SegmentedDataSource: DataSourceUpdateDelegate {

    public func dataSource(_ dataSource: DataSource, performUpdates changeDetails: ComposedChangeDetails) {
        updateDelegate?.dataSource(self, performUpdates: changeDetails)
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
