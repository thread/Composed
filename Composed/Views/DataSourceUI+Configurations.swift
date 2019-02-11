import UIKit

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
