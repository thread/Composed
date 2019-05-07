import UIKit

@available(*, deprecated, renamed: "DataSourceUIConfiguration")
public typealias DataSourceUIConfiguration = CollectionUIViewProvider

public final class CollectionUIViewProvider {

    public enum Source {
        case nib
        case `class`
    }

    public enum Context {
        case sizing
        case presentation
    }

    public typealias ViewType = UICollectionReusableView

    public let dequeueSource: Source
    public let configure: (UICollectionReusableView, IndexPath, Context) -> Void

    private let prototypeProvider: () -> UICollectionReusableView
    private var _prototypeView: UICollectionReusableView?

    public var prototype: UICollectionReusableView {
        if let view = _prototypeView { return view }
        let view = prototypeProvider()
        _prototypeView = view
        return view
    }

    public private(set) lazy var reuseIdentifier: String = {
        return prototype.reuseIdentifier ?? type(of: prototype).reuseIdentifier
    }()

    public init<View>(prototype: @escaping @autoclosure () -> View, dequeueSource: Source, reuseIdentifier: String? = nil, _ configure: @escaping (View, IndexPath, Context) -> Void) where View: UICollectionReusableView {

        self.prototypeProvider = prototype
        self.dequeueSource = dequeueSource
        self.configure = { view, indexPath, context in
            // swiftlint:disable force_cast
            configure(view as! View, indexPath, context)
        }

        if let reuseIdentifier = reuseIdentifier {
            self.reuseIdentifier = reuseIdentifier
        }
    }

}
