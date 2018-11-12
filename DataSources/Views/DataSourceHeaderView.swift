import UIKit

/**
 A `UICollectionReusableView` subclass that is intended to be used as the subclass
 for headers and footers in collection views.

 By default this class simply overrides the class property `layerClass` to
 always return 0 for the `zPosition`. This is to workaround an iOS bug that
 causes headers to render over the scrollbar
 */
open class DataSourceHeaderView: UICollectionReusableView {

    open override class var layerClass: AnyClass {
        return FixedZPositionLayer.self
    }

    public private(set) var isEditing: Bool = false

    open func setEditing(_ editing: Bool, animated: Bool) {
        isEditing = editing
    }

}

/**
 A `CALayer` subclass that always returns `0` for the `zPosition`
 */
private final class FixedZPositionLayer: CALayer {

    override var zPosition: CGFloat {
        get { return 0 }
        set { /* no-op */ }
    }

}
