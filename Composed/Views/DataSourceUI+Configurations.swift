import UIKit

public struct DataSourceUIInvalidationContext {

    public var invalidateGlobalHeader: Bool = false
    public var invalidateGlobalFooter: Bool = false

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

public struct DataSourceUIConfiguration {

    public enum Source {
        case nib
        case `class`
    }

    public typealias ViewType = UICollectionReusableView

    public let dequeueSource: Source
    public let reuseIdentifier: String
    public let prototype: UICollectionReusableView
    public let configure: (UICollectionReusableView, IndexPath) -> Void

    public init<View>(prototype: View, dequeueSource: Source, reuseIdentifier: String? = nil, _ configure: @escaping (View, IndexPath) -> Void) where View: UICollectionReusableView {
        self.reuseIdentifier = reuseIdentifier ?? prototype.reuseIdentifier ?? type(of: prototype).reuseIdentifier
        self.prototype = prototype
        self.dequeueSource = dequeueSource
        self.configure = { view, indexPath in
            configure(view as! View, indexPath)
        }
    }

}
