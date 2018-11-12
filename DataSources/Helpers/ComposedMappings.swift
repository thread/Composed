public final class ComposedMappings {

    public private(set) unowned var dataSource: DataSource

    internal private(set) var numberOfSections: Int = 0
    private var globalToLocalSections: [Int: Int] = [:]
    private var localToGlobalSections: [Int: Int] = [:]

    public init(_ dataSource: DataSource, initialSection: Int = 0) {
        self.dataSource = dataSource
        guard initialSection == 0 else { return }
        invalidate(startAtGlobalSection: initialSection, { _ in })
    }

    public func localSection(forGlobal section: Int) -> Int {
        let localIndex = globalToLocalSections[section]
        assert(localIndex != nil, "global section \(section) not found in local sections")
        return globalToLocalSections[section]!
    }

    public func globalSection(forLocal section: Int) -> Int {
        let globalIndex = localToGlobalSections[section]
        assert(globalIndex != nil, "local section \(section) not found in global sections")
        return localToGlobalSections[section]!
    }

    public func localSections(forGlobal sections: IndexSet) -> IndexSet {
        var localIndexes = IndexSet()

        for section in sections {
            localIndexes.insert(localSection(forGlobal: section))
        }

        return localIndexes
    }

    public func globalSections(forLocal sections: IndexSet) -> IndexSet {
        var globalIndexes = IndexSet()

        for section in sections {
            globalIndexes.insert(globalSection(forLocal: section))
        }

        return globalIndexes
    }

    public func localIndexPath(forGlobal indexPath: IndexPath) -> IndexPath {
        let section = localSection(forGlobal: indexPath.section)
        return IndexPath(item: indexPath.item, section: section)
    }

    public func globalIndexPath(forLocal indexPath: IndexPath) -> IndexPath {
        let section = globalSection(forLocal: indexPath.section)
        return IndexPath(item: indexPath.item, section: section)
    }

    public func localIndexPaths(forGlobal indexPaths: [IndexPath]) -> [IndexPath] {
        return indexPaths.compactMap(localIndexPath(forGlobal:))
    }

    public func globalIndexPaths(forLocal indexPaths: [IndexPath]) -> [IndexPath] {
        return indexPaths.compactMap(globalIndexPath(forLocal:))
    }

    internal func invalidate(startAtGlobalSection section: Int, _ closure: (Int) -> Void) {
        numberOfSections = dataSource.numberOfSections
        globalToLocalSections.removeAll()
        localToGlobalSections.removeAll()

        var globalSection = section
        for localSection in 0..<numberOfSections {
            addMapping(fromGlobal: globalSection, toLocal: localSection)
            closure(globalSection)
            globalSection += 1
        }
    }

    private func addMapping(fromGlobal globalSection: Int, toLocal localSection: Int) {
        assert(localToGlobalSections[localSection] == nil,
               "Collision while trying to add a mapping from global section: \(globalSection), to local section: \(localSection)")
        globalToLocalSections[globalSection] = localSection
        localToGlobalSections[localSection] = globalSection
    }

}

extension ComposedMappings: Equatable {

    public static func == (lhs: ComposedMappings, rhs: ComposedMappings) -> Bool {
        return AnyDataSource(lhs.dataSource) == AnyDataSource(rhs.dataSource)
    }

}
