import UIKit

public extension DataStoreDelegate {
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataStore(didInsertSections sections: IndexSet) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataStore(didDeleteSections sections: IndexSet) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataStore(didUpdateSections sections: IndexSet) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataStore(didMoveSection from: Int, to: Int) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataStore(didInsertIndexPaths indexPaths: [IndexPath]) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataStore(didDeleteIndexPaths indexPaths: [IndexPath]) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataStore(didUpdateIndexPaths indexPaths: [IndexPath]) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataStore(didMoveFromIndexPath from: IndexPath, toIndexPath to: IndexPath) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataStoreDidReload() { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataStore(performBatchUpdates updates: () -> Void, completion: ((Bool) -> Void)?) { fatalError() }
}

public extension ArrayDataStore {

    @available(*, deprecated, renamed: "replaceElements(_:changesets:)")
    func setElements(_ elements: [Element], changesets: [DataSourceChangeset]? = nil) {
        replaceElements(elements, changesets: changesets)
    }

}

public extension DataSourceUpdateDelegate {
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet) { fatalError()}
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataSource(_ dataSource: DataSource, didDeleteSections sections: IndexSet) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataSource(_ dataSource: DataSource, didUpdateSections sections: IndexSet) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataSource(_ dataSource: DataSource, didMoveSection from: Int, to: Int) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataSource(_ dataSource: DataSource, didInsertIndexPaths indexPaths: [IndexPath]) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataSource(_ dataSource: DataSource, didDeleteIndexPaths indexPaths: [IndexPath]) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataSource(_ dataSource: DataSource, didUpdateIndexPaths indexPaths: [IndexPath]) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataSource(_ dataSource: DataSource, didMoveFromIndexPath from: IndexPath, toIndexPath to: IndexPath) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataSourceDidReload(_ dataSource: DataSource) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataSource(_ dataSource: DataSource, performBatchUpdates updates: () -> Void, completion: ((Bool) -> Void)?) { fatalError() }
    @available(swift, obsoleted: 1.0, message: "This is no longer required and has been removed entirely. Calling this method results in a fatalError")
    func dataSource(_ dataSource: DataSource, globalFor local: IndexPath) -> (dataSource: DataSource, globalIndexPath: IndexPath) { fatalError() }
    @available(*, deprecated, renamed: "dataSource(_:sectionFor:)")
    func dataSource(_ dataSource: DataSource, globalFor local: Int) -> (dataSource: DataSource, globalSection: Int) {
        return self.dataSource(dataSource, sectionFor: local)
    }
}

public extension DataSource {
    @available(*, deprecated, renamed: "localSection(for:)")
    func dataSourceFor(global section: Int) -> (dataSource: DataSource, localSection: Int) { return localSection(for: section) }
    @available(*, deprecated, message: "Use localSection(for:) – Map the section, then set indexPath.item manually, it remains unchanged")
    func dataSourceFor(global indexPath: IndexPath) -> (dataSource: DataSource, localIndexPath: IndexPath) {
        let global = localSection(for: indexPath.section)
        return (global.dataSource, IndexPath(item: indexPath.item, section: global.localSection) )
    }
}

public extension DataSourceInvalidationContext {
    @available(*, deprecated, renamed: "refreshElements(at:)")
    mutating func reloadElements(at indexPaths: [IndexPath]) {
        refreshElements(at: indexPaths)
    }
    @available(*, deprecated, renamed: "refreshHeaders(in:)")
    mutating func reloadHeaders(in sections: IndexSet) {
        refreshHeaders(in: sections)
    }
    @available(*, deprecated, renamed: "refreshFooters(in:)")
    mutating func reloadFooters(in sections: IndexSet) {
        refreshFooters(in: sections)
    }
}

@available(*, deprecated, renamed: "EditHandling")
public typealias DataSourceUIEditingView = EditHandling
@available(*, deprecated, renamed: "EditHandlingDataSource")
public typealias DataSourceUIEditing = EditHandlingDataSource
@available(*, deprecated, renamed: "SelectionHandlingDataSource")
public typealias DataSourceSelecting = SelectionHandlingDataSource
@available(swift, obsoleted: 1.0, message: "Lifecycle support is no longer provided")
public protocol LifecycleObservingDataSource { }
@available(*, deprecated, renamed: "GlobalProvidingDataSource")
public typealias DataSourceUIGlobalProviding = GlobalViewsProvidingDataSource
@available(*, deprecated, renamed: "GlobalViewsProvidingDataSource")
public typealias DataSourceUIGlobalProvider = GlobalViewsProvidingDataSource
@available(*, deprecated, renamed: "CollectionUIProvidingDataSource")
public typealias DataSourceUIProviding = CollectionUIProvidingDataSource

@available(*, deprecated, renamed: "CollectionUISectionMetrics")
public typealias DataSourceUISectionMetrics = CollectionUISectionMetrics
@available(*, deprecated, renamed: "CollectionUISizingContext")
public typealias DataSourceUISizingContext = CollectionUISizingContext
@available(*, deprecated, renamed: "CollectionUISizingStrategy")
public typealias DataSourceUISizingStrategy = CollectionUISizingStrategy
@available(*, deprecated, renamed: "CollectionUIViewProvider")
public typealias DataSourceUIConfiguration = CollectionUIViewProvider
@available(*, deprecated, renamed: "EditHandling")
public typealias DataSourceEditableView = EditHandling

extension CollectionUIViewProvider {
    @available(*, deprecated, renamed: "init(prototype:dequeueMethod:reuseIdentifier:_:)")
    public convenience init<View>(prototype: @escaping @autoclosure () -> View, dequeueSource: DequeueMethod, reuseIdentifier: String? = nil, _ configure: @escaping (View, IndexPath, Context) -> Void) where View: UICollectionReusableView {
        self.init(prototype: prototype(), dequeueMethod: dequeueSource, reuseIdentifier: reuseIdentifier, configure)
    }
}

public extension SelectionHandlingDataSource {
    @available(*, deprecated, renamed: "selectionHandler(forElementAt:)")
    func shouldSelectElement(at indexPath: IndexPath) -> Bool { return false }
    @available(*, deprecated, renamed: "deselectionHandler(forElementAt:)")
    func shouldDeselectElement(at indexPath: IndexPath) -> Bool { return false }
}

@available(*, deprecated, renamed: "LayoutBackgroundStyle")
@objc public enum LayoutReference : Int {
    @available(*, deprecated, renamed: "innerBounds")
    case fromBoundsExcludingHeadersAndFooters
    @available(*, deprecated, renamed: "outerBounds")
    case fromBounds
    @available(*, deprecated, message: "The enum no longer provides automatic insets. Instead use the dedicated delegate function backgroundLayoutInsets(for:)")
    case fromSectionInsets
}

public extension CollectionUIProvidingDataSource {
    @available(*, deprecated, message: "This function no longer exists. Please configure these properties on the CollectionUIBackgroundProvider")
    func backgroundLayoutReference(for section: Int) -> LayoutReference { fatalError() }
    @available(*, deprecated, message: "Please use the new backgroundConfiguration(for:) that returns a CollectionUIBackgroundProvider")
    func backgroundConfiguration(for section: Int) -> CollectionUIViewProvider? { fatalError() }
}
