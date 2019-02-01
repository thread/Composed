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

}

/**
 A `CALayer` subclass that always returns `0` for the `zPosition`
 */
private final class FixedZPositionLayer: CALayer {

    private var _zPosition: CGFloat = 0
    override var zPosition: CGFloat {
        get { return _zPosition }
        set { _zPosition = newValue }
    }

}
