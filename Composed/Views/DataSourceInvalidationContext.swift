import Foundation

public struct DataSourceInvalidationContext {

    private var _invalidateGlobalHeader: Bool = false
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

    public var invalidateLayoutMetrics: Bool = false

    public private(set) var reloadingElementIndexPaths: Set<IndexPath> = []
    public private(set) var reloadingHeaderIndexes = IndexSet()
    public private(set) var reloadingFooterIndexes = IndexSet()

    public mutating func reloadElements(at indexPaths: [IndexPath]) {
        indexPaths.forEach { reloadingElementIndexPaths.insert($0) }
    }

    public mutating func reloadHeaders(in sections: IndexSet) {
        sections.forEach { reloadingHeaderIndexes.insert($0) }
    }

    public mutating func reloadFooters(in sections: IndexSet) {
        sections.forEach { reloadingFooterIndexes.insert($0) }
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
}
