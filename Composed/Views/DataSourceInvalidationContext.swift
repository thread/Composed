import Foundation

/// Describes the invalidation to perform on both a DataSource and a UICollectionViewLayout instance.
///
/// The implementation mirrors much of what you'd expect, with a few additions like refreshing (not reloading) of individual elements, support for global elements, etc...
public struct DataSourceInvalidationContext {

    private var _invalidateGlobalHeader: Bool = false

    /// If true, the global header will be invalidated
    public var invalidateGlobalHeader: Bool {
        get { return _invalidateGlobalHeader }
        set {
            // we don't want to enable setting this to false once its true
            guard newValue else { return }
            _invalidateGlobalHeader = newValue
            _invalidateGlobalHeaderData = newValue
            _invalidateGlobalHeaderMetrics = newValue
        }
    }

    private var _invalidateGlobalFooter: Bool = false

    /// If true, the global footer will be invalidated
    public var invalidateGlobalFooter: Bool {
        get { return _invalidateGlobalFooter }
        set {
            // we don't want to enable setting this to false once its true
            guard newValue else { return }
            _invalidateGlobalFooter = newValue
            _invalidateGlobalFooterData = newValue
            _invalidateGlobalFooterMetrics = newValue
        }
    }

    private var _invalidateGlobalHeaderData: Bool = false
    public var invalidateGlobalHeaderData: Bool {
        get { return _invalidateGlobalHeaderData }
        set {
            // we don't want to enable setting this to false once its true
            guard newValue else { return }
            _invalidateGlobalHeaderData = newValue
        }
    }

    private var _invalidateGlobalFooterData: Bool = false
    public var invalidateGlobalFooterData: Bool {
        get { return _invalidateGlobalFooterData }
        set {
            // we don't want to enable setting this to false once its true
            guard newValue else { return }
            _invalidateGlobalFooterData = newValue
        }
    }

    private var _invalidateGlobalHeaderMetrics: Bool = false
    public var invalidateGlobalHeaderMetrics: Bool {
        get { return _invalidateGlobalHeaderMetrics }
        set {
            // we don't want to enable setting this to false once its true
            guard newValue else { return }
            _invalidateGlobalHeaderMetrics = newValue
        }
    }

    private var _invalidateGlobalFooterMetrics: Bool = false
    public var invalidateGlobalFooterMetrics: Bool {
        get { return _invalidateGlobalFooterMetrics }
        set {
            // we don't want to enable setting this to false once its true
            guard newValue else { return }
            _invalidateGlobalFooterMetrics = newValue
        }
    }

    // if set to false, the layout will not requery the delegate for size information etc.
    public var invalidateLayoutMetrics: Bool = false

    public private(set) var refreshElementsIndexPaths: Set<IndexPath> = []
    public private(set) var refreshHeaderIndexes = IndexSet()
    public private(set) var refreshFooterIndexes = IndexSet()

    public mutating func refreshElements(at indexPaths: [IndexPath]) {
        indexPaths.forEach { refreshElementsIndexPaths.insert($0) }
    }

    public mutating func refreshHeaders(in sections: IndexSet) {
        sections.forEach { refreshHeaderIndexes.insert($0) }
    }

    public mutating func refreshFooters(in sections: IndexSet) {
        sections.forEach { refreshFooterIndexes.insert($0) }
    }

    public private(set) var invalidatedElementIndexPaths: Set<IndexPath> = []
    public private(set) var invalidatedHeaderIndexes = IndexSet()
    public private(set) var invalidatedFooterIndexes = IndexSet()

    public mutating func invalidateElements(at indexPaths: [IndexPath]) {
        indexPaths.forEach { invalidatedElementIndexPaths.insert($0) }
    }

    public mutating func invalidateHeaders(in sections: IndexSet) {
        sections.forEach { invalidatedHeaderIndexes.insert($0) }
    }

    public mutating func invalidateFooters(in sections: IndexSet) {
        sections.forEach { invalidatedFooterIndexes.insert($0) }
    }

    public init() { }
    internal static func make(from context: DataSourceInvalidationContext) -> DataSourceInvalidationContext {
        var globalContext = DataSourceInvalidationContext()
        globalContext.invalidateGlobalHeader = context.invalidateGlobalHeader
        globalContext.invalidateGlobalFooter = context.invalidateGlobalFooter
        globalContext.invalidateLayoutMetrics = context.invalidateLayoutMetrics
        globalContext.invalidateGlobalFooterData = context.invalidateGlobalFooterData
        globalContext.invalidateGlobalHeaderData = context.invalidateGlobalHeaderData
        globalContext.invalidateGlobalHeaderMetrics = context.invalidateGlobalHeaderMetrics
        globalContext.invalidateGlobalFooterMetrics = context.invalidateGlobalFooterMetrics
        return globalContext
    }
}
