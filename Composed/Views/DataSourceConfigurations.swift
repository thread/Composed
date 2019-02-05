import UIKit

public struct CellConfiguration {

    public enum Source {
        case nib
        case `class`
    }

    public let dequeueSource: Source
    public let prototype: DataSourceCell
    public let configure: (DataSourceCell, IndexPath) -> Void

    public init<Cell>(prototype: Cell, dequeueSource: Source, _ configure: @escaping (Cell, IndexPath) -> Void) where Cell: DataSourceCell {
        self.prototype = prototype
        self.dequeueSource = dequeueSource
        self.configure = { cell, indexPath in
            guard let cell = cell as? Cell else { return }
            configure(cell, indexPath)
        }
    }

}

public struct HeaderFooterConfiguration {

    public enum Source {
        case nib
        case `class`
    }

    public let dequeueSource: Source
    public let prototype: UICollectionReusableView
    public let configure: (UICollectionReusableView, Int) -> Void

    public init<View>(prototype: View, dequeueSource: Source, _ configure: @escaping (View, Int) -> Void) where View: UICollectionReusableView {
        self.prototype = prototype
        self.dequeueSource = dequeueSource
        self.configure = { view, section in
            guard let view = view as? View else { return }
            configure(view, section)
        }
    }

}
