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

public struct DataSourceUICellConfiguration {

    public enum Source {
        case nib
        case `class`
    }

    public let dequeueSource: Source
    public let reuseIdentifier: String
    public let prototype: UICollectionViewCell
    public let configure: (UICollectionViewCell, IndexPath) -> Void

    public init<Cell>(prototype: Cell, dequeueSource: Source, reuseIdentifier: String? = nil, _ configure: @escaping (Cell, IndexPath) -> Void) where Cell: UICollectionViewCell {
        self.reuseIdentifier = reuseIdentifier ?? prototype.reuseIdentifier ?? type(of: prototype).reuseIdentifier
        self.prototype = prototype
        self.dequeueSource = dequeueSource
        self.configure = { cell, indexPath in
            guard let cell = cell as? Cell else { return }
            configure(cell, indexPath)
        }
    }

}

public struct DataSourceUIViewConfiguration {

    public enum Source {
        case nib
        case `class`
    }

    public let dequeueSource: Source
    public let reuseIdentifier: String
    public let prototype: UICollectionReusableView
    public let configure: (UICollectionReusableView, Int) -> Void

    public init<View>(prototype: View, dequeueSource: Source, reuseIdentifier: String? = nil, _ configure: @escaping (View, Int) -> Void) where View: UICollectionReusableView {
        self.reuseIdentifier = reuseIdentifier ?? prototype.reuseIdentifier ?? type(of: prototype).reuseIdentifier
        self.prototype = prototype
        self.dequeueSource = dequeueSource
        self.configure = { view, section in
            guard let view = view as? View else { return }
            configure(view, section)
        }
    }

}
