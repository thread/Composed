import Foundation

open class ComposedDataSource: AggregateDataSource {

    public var descendants: [DataSource] {
        var descendants: [DataSource] = []

        for child in children {
            if let aggregate = child as? AggregateDataSource {
                descendants.append(contentsOf: [child] + aggregate.descendants)
            } else {
                descendants.append(child)
            }
        }

        return descendants
    }

    public weak var updateDelegate: DataSourceUpdateDelegate? {
        didSet {
            if updateDelegate == nil {
                willResignActive()
            } else {
                if isActive { didBecomeActive() }
            }
        }
    }

    public var children: [DataSource] {
        return mappings.map { $0.dataSource }
    }

    private var mappings: [ComposedMappings] = []
    private var globalSectionToMapping: [Int: ComposedMappings] = [:]
    private var dataSourceToMappings: [DataSourceHashableWrapper: ComposedMappings] = [:]

    private var _numberOfSections: Int = 0
    public var numberOfSections: Int {
        _invalidate()
        return _numberOfSections
    }

    public final func numberOfElements(in section: Int) -> Int {
        _invalidate()

        let mapping = self.mapping(for: section)
        let local = mapping.localSection(forGlobal: section)

        let numberOfSections = mapping.dataSource.numberOfSections
        assert(local < numberOfSections, "local section is out of public bounds for composed data source")

        return mapping.dataSource.numberOfElements(in: local)
    }

    public init(children: [DataSource] = []) {
        children.reversed().forEach { _insert(dataSource: $0, at: 0) }
    }

    public final func setDataSources(_ dataSources: [DataSource], animated: Bool) {
        removeAll()
        dataSources.reversed().forEach { _insert(dataSource: $0, at: 0) }
        let details = ComposedChangeDetails(hasIncrementalChanges: false)
        updateDelegate?.dataSource(self, performUpdates: details)
    }

    public func append(_ dataSource: DataSource) {
        insert(dataSource: dataSource, at: mappings.count)
    }

    public final func insert(dataSource: DataSource, at index: Int) {
        let indexes = _insert(dataSource: dataSource, at: index)
        var details = ComposedChangeDetails()
        details.insertedSections = IndexSet(indexes)
        updateDelegate?.dataSource(self, performUpdates: details)
    }

    @discardableResult
    private final func _insert(dataSource: DataSource, at index: Int) -> [Int] {
        let wrapper = DataSourceHashableWrapper(dataSource)

        guard !dataSourceToMappings.keys.contains(wrapper) else {
            assertionFailure("\(wrapper.dataSource) has already been inserted")
            return []
        }

        guard (0...children.count).contains(index) else {
            assertionFailure("Index out of bounds for \(wrapper.dataSource)")
            return []
        }

        wrapper.dataSource.updateDelegate = self

        let mapping = ComposedMappings(wrapper.dataSource)
        mappings.insert(mapping, at: index)
        dataSourceToMappings[wrapper] = mapping

        _invalidate()

        if isActive {
            children
                .lazy
                .compactMap { $0 as? LifecycleObservingDataSource }
                .forEach { $0.prepare() }

            children
                .lazy
                .compactMap { $0 as? LifecycleObservingDataSource }
                .forEach { $0.didBecomeActive() }
        }

        return (0..<wrapper.dataSource.numberOfSections).map(mapping.globalSection(forLocal:))
    }

    public final func remove(dataSource: DataSource) {
        let indexes = _remove(dataSource: dataSource)
        var details = ComposedChangeDetails()
        details.removedSections = IndexSet(indexes)
        updateDelegate?.dataSource(self, performUpdates: details)
    }

    @discardableResult
    private func _remove(dataSource: DataSource) -> [Int] {
        let wrapper = DataSourceHashableWrapper(dataSource)

        guard let mapping = dataSourceToMappings[wrapper] else {
            fatalError("\(wrapper.dataSource) is not a child of this dataSource")
        }

        let removedSections = (0..<wrapper.dataSource.numberOfSections)
            .map(mapping.globalSection(forLocal:))
        dataSourceToMappings[DataSourceHashableWrapper(wrapper.dataSource)] = nil

        if let index = mappings.firstIndex(where: { DataSourceHashableWrapper($0.dataSource) == wrapper }) {
            mappings.remove(at: index)
        }

        wrapper.dataSource.updateDelegate = nil

        _invalidate()

        children.lazy
            .compactMap { $0 as? LifecycleObservingDataSource }
            .forEach { $0.willResignActive() }

        children.lazy
            .compactMap { $0 as? LifecycleObservingDataSource }
            .forEach { $0.invalidate() }

        return removedSections
    }

    public final func removeAll() {
        let indexes = dataSourceToMappings.flatMap {
            _remove(dataSource: $0.key.dataSource)
        }

        var details = ComposedChangeDetails()
        details.removedSections = IndexSet(indexes)
        updateDelegate?.dataSource(self, performUpdates: details)
    }

    private func _invalidate() {
        _numberOfSections = 0
        globalSectionToMapping.removeAll()

        for mapping in mappings {
            mapping.invalidate(startingAt: _numberOfSections) { section in
                globalSectionToMapping[section] = mapping
            }

            _numberOfSections += mapping.numberOfSections
        }
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
        children
            .lazy
            .compactMap { $0 as? LifecycleObservingDataSource }
            .forEach { $0.didBecomeActive() }
    }

    open func willResignActive() {
        children
            .lazy
            .compactMap { $0 as? LifecycleObservingDataSource }
            .forEach { $0.willResignActive() }
    }

}

extension ComposedDataSource {

    private func localDataSourceAndIndexPath(for indexPath: IndexPath) -> (DataSource, IndexPath) {
        let dataSource = self.dataSource(forSection: indexPath.section)
        let mapping = self.mapping(for: indexPath.section)
        let local = mapping.localIndexPath(forGlobal: indexPath)
        return (dataSource, local)
    }

    private func localDataSourceAndSection(for section: Int) -> (DataSource, Int) {
        let dataSource = self.dataSource(forSection: section)
        let mapping = self.mapping(for: section)
        let local = mapping.localSection(forGlobal: section)
        return (dataSource, local)
    }

    public final func localSection(for section: Int) -> (dataSource: DataSource, localSection: Int) {
        let mapping = self.mapping(for: section)
        let local = mapping.localSection(forGlobal: section)
        return mapping.dataSource.localSection(for: local)
    }

}

public extension ComposedDataSource {

    func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath? {
        for child in children {
            if let indexPath = child.indexPath(where: predicate) {
                let mapping = self.mapping(for: child)
                return mapping.globalIndexPath(forLocal: indexPath)
            }
        }

        return nil
    }
    
}

private extension ComposedDataSource {

    func dataSource(forSection section: Int) -> DataSource {
        return mapping(for: section).dataSource
    }

    func mapping(for section: Int) -> ComposedMappings {
        return globalSectionToMapping[section]!
    }

    func mapping(for dataSource: DataSource) -> ComposedMappings {
        return dataSourceToMappings[DataSourceHashableWrapper(dataSource)]!
    }

    func globalSections(forLocalSections sections: IndexSet, inDataSource dataSource: DataSource) -> IndexSet {
        let mapping = self.mapping(for: dataSource)
        return IndexSet(sections.map { mapping.globalSection(forLocal: $0) })
    }

    func globalIndexPaths(forLocalIndexPaths indexPaths: [IndexPath], inDataSource dataSource: DataSource) -> [IndexPath] {
        let mapping = self.mapping(for: dataSource)
        return indexPaths.map { mapping.globalIndexPath(forLocal: $0) }
    }

}

extension ComposedDataSource: DataSourceUpdateDelegate {

    public func dataSource(_ dataSource: DataSource, performUpdates changeDetails: ComposedChangeDetails) {
        var details = ComposedChangeDetails(hasIncrementalChanges: changeDetails.hasIncrementalChanges)
        let mapping = self.mapping(for: dataSource)

        details.insertedSections = IndexSet(changeDetails.insertedSections.map(mapping.globalSection(forLocal:)))
        details.insertedIndexPaths = changeDetails.insertedIndexPaths
        details.removedSections = IndexSet(changeDetails.removedSections.map(mapping.globalSection(forLocal:)))
        details.removedIndexPaths = changeDetails.removedIndexPaths
        details.updatedSections = IndexSet(changeDetails.updatedSections.map(mapping.globalSection(forLocal:)))
        details.updatedIndexPaths = changeDetails.updatedIndexPaths
        details.movedSections = changeDetails.movedSections.map(mapping.globalSections(forLocal:))
        details.movedIndexPaths = changeDetails.movedIndexPaths.map(mapping.globalIndexPaths(forLocal:))

        _invalidate()
        updateDelegate?.dataSource(self, performUpdates: details)
    }

    public final func dataSource(_ dataSource: DataSource, invalidateWith context: DataSourceInvalidationContext) {
        var globalContext = DataSourceInvalidationContext()
        globalContext.invalidateGlobalHeader = context.invalidateGlobalHeader
        globalContext.invalidateGlobalFooter = context.invalidateGlobalFooter

        let elementIndexPaths = globalIndexPaths(forLocalIndexPaths: Array(context.invalidatedElementIndexPaths), inDataSource: dataSource)
        globalContext.invalidateElements(at: elementIndexPaths)

        let headerIndexes = globalSections(forLocalSections: context.invalidatedHeaderIndexes, inDataSource: dataSource)
        globalContext.invalidateHeaders(in: headerIndexes)

        let footerIndexes = globalSections(forLocalSections: context.invalidatedFooterIndexes, inDataSource: dataSource)
        globalContext.invalidateHeaders(in: footerIndexes)

        updateDelegate?.dataSource(self, invalidateWith: globalContext)
    }

    public func dataSource(_ dataSource: DataSource, sectionFor local: Int) -> (dataSource: DataSource, globalSection: Int) {
        let mapping = self.mapping(for: dataSource)
        let global = mapping.globalSection(forLocal: local)
        return updateDelegate?.dataSource(self, sectionFor: global) ?? (self, global)
    }

}
