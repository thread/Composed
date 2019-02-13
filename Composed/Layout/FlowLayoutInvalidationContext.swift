import UIKit

public final class FlowLayoutInvalidationContext: UICollectionViewFlowLayoutInvalidationContext {

    private var _invalidateGlobalHeader: Bool = false
    public var invalidateGlobalHeader: Bool {
        get { return _invalidateGlobalHeader }
        set {
            // we don't want to enable setting this to false once its true
            guard newValue else { return }
            _invalidateGlobalHeader = newValue
            invalidateSupplementaryElements(ofKind: UICollectionView.elementKindGlobalHeader, at: [UICollectionView.globalElementIndexPath])
        }
    }

    private var _invalidateGlobalFooter: Bool = false
    public var invalidateGlobalFooter: Bool {
        get { return _invalidateGlobalFooter }
        set {
            // we don't want to enable setting this to false once its true
            guard newValue else { return }
            _invalidateGlobalFooter = newValue
            invalidateSupplementaryElements(ofKind: UICollectionView.elementKindGlobalFooter, at: [UICollectionView.globalElementIndexPath])
        }
    }

}
