import UIKit

public struct GlobalAttributes {

    public enum Reference {
        case none
        case fromSafeArea
    }

    public var pinsToBounds: Bool = true
    public var pinsToContent: Bool = false
    public var prefersFollowContent: Bool = true

    public var inset: CGFloat = 0
    public var respectSafeAreaForPosition: Bool = true
    public var respectSafeAreaForSize: Bool = true

    internal init() { }

}

open class FlowLayout: UICollectionViewFlowLayout {

    open override class var layoutAttributesClass: AnyClass {
        return FlowLayoutAttributes.self
    }

    open override class var invalidationContextClass: AnyClass {
        return FlowLayoutInvalidationContext.self
    }

    public var globalHeader = GlobalAttributes()
    public var globalFooter = GlobalAttributes()

    internal private(set) var cachedGlobalHeaderSize: CGSize = .zero
    internal private(set) var cachedGlobalFooterSize: CGSize = .zero

    public init(metrics: FlowLayoutSectionMetrics? = nil) {
        super.init()

        headerReferenceSize = CGSize(width: 0, height: metrics?.headerHeight ?? 0)
        footerReferenceSize = CGSize(width: 0, height: metrics?.footerHeight ?? 0)

        sectionInset = metrics?.insets ?? .zero
        minimumInteritemSpacing = metrics?.horizontalSpacing ?? 0
        minimumLineSpacing = metrics?.verticalSpacing ?? 0
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }

        if cachedGlobalHeaderSize == .zero {
            cachedGlobalHeaderSize = sizeForGlobalHeader

            if cachedGlobalHeaderSize != .zero,
                isNavigationBarHidden,
                globalHeader.respectSafeAreaForSize {
                cachedGlobalHeaderSize.height += collectionView.safeAreaInsets.top
            }
        }

        if cachedGlobalFooterSize == .zero {
            cachedGlobalFooterSize = sizeForGlobalFooter

            if cachedGlobalFooterSize != .zero,
                isTabBarHidden,
                globalFooter.respectSafeAreaForSize {
                cachedGlobalFooterSize.height += collectionView.safeAreaInsets.bottom
            }
        }
    }

    open override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
        guard let context = context as? FlowLayoutInvalidationContext else { return }

        if context.invalidateGlobalHeader {
            cachedGlobalHeaderSize = .zero
        }

        if context.invalidateGlobalFooter {
            cachedGlobalFooterSize = .zero
        }
    }

    open override var collectionViewContentSize: CGSize {
        var size = super.collectionViewContentSize
        size.height += adjustedOrigin
        size.height += cachedGlobalHeaderSize.height + globalHeader.inset
        size.height += cachedGlobalFooterSize.height + globalFooter.inset
        return size
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let originalAttributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes
        guard requiresLayout else { return originalAttributes }
        originalAttributes.map { ($0.frame, $0.zIndex) = adjustedFrame(for: $0) }
        return originalAttributes
    }

    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let originalAttributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)?.copy() as? UICollectionViewLayoutAttributes
        guard requiresLayout else { return originalAttributes }

        switch elementKind {
        case UICollectionView.elementKindGlobalHeader:
            let attributes = FlowLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
            attributes.frame = CGRect(origin: .zero, size: cachedGlobalHeaderSize)
            (attributes.frame, attributes.zIndex) = adjustedFrame(for: attributes)
            return attributes
        case UICollectionView.elementKindGlobalFooter:
            let attributes = FlowLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
            attributes.frame = CGRect(origin: .zero, size: cachedGlobalFooterSize)
            (attributes.frame, attributes.zIndex) = adjustedFrame(for: attributes)
            return attributes
        default:
            originalAttributes.map { ($0.frame, $0.zIndex) = adjustedFrame(for: $0) }
            return originalAttributes
        }
    }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let rect = rect.insetBy(dx: 0, dy: -cachedGlobalHeaderSize.height)

        var attributes = NSArray(array: super.layoutAttributesForElements(in: rect) ?? [], copyItems: true) as? [UICollectionViewLayoutAttributes]
        guard requiresLayout else { return attributes }

        attributes?.forEach { ($0.frame, $0.zIndex) = adjustedFrame(for: $0) }

        if cachedGlobalHeaderSize.height > 0,
            let header = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindGlobalHeader,
                                                              at: UICollectionView.globalElementIndexPath) {
            attributes?.append(header)
        }

        if cachedGlobalFooterSize.height > 0,
            let footer = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindGlobalFooter,
                                                                  at: UICollectionView.globalElementIndexPath) {
            attributes?.append(footer)
        }

        return attributes
    }

    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if requiresLayout { return true }
        return super.shouldInvalidateLayout(forBoundsChange: newBounds)
    }

    open override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        guard requiresLayout,
            let context = super.invalidationContext(forBoundsChange: newBounds) as? UICollectionViewFlowLayoutInvalidationContext,
            let oldBounds = collectionView?.bounds
            else {
                return super.invalidationContext(forBoundsChange: newBounds)
        }

        if oldBounds.size != newBounds.size {
            context.invalidateFlowLayoutDelegateMetrics = true
        }

        if oldBounds.origin != newBounds.origin {
            if cachedGlobalHeaderSize.height > 0 {
                context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindGlobalHeader, at: [UICollectionView.globalElementIndexPath])
            }

            if cachedGlobalFooterSize.height > 0 {
                context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindGlobalFooter, at: [UICollectionView.globalElementIndexPath])
            }
        }

        return context
    }

}

private extension FlowLayout {

    var adjustedOrigin: CGFloat {
        return cachedGlobalHeaderSize != .zero
            && isNavigationBarHidden
            && globalHeader.respectSafeAreaForPosition
            ? -collectionView!.safeAreaInsets.top
            : 0
    }

    func adjustedFrame(for attributes: UICollectionViewLayoutAttributes) -> (frame: CGRect, zIndex: Int) {
        guard let collectionView = collectionView else { return (attributes.frame, 0) }

        switch attributes.representedElementKind {
        case UICollectionView.elementKindGlobalHeader:
            var frame = attributes.frame

            if globalHeader.pinsToBounds {
                if globalHeader.prefersFollowContent, collectionView.contentOffset.y + collectionView.adjustedContentInset.top >= 0 {
                    frame.origin.y = adjustedOrigin
                } else {
                    frame.origin.y = adjustedOrigin + collectionView.contentOffset.y + collectionView.adjustedContentInset.top
                }
            }

            if globalHeader.pinsToBounds
                && globalHeader.pinsToContent
                && collectionView.contentOffset.y < -collectionView.adjustedContentInset.top {
                frame.size.height = max(cachedGlobalHeaderSize.height, cachedGlobalHeaderSize.height - frame.minY + adjustedOrigin)
            }

            return (frame, 400)
        case UICollectionView.elementKindGlobalFooter:
            var frame = attributes.frame

            frame.origin.y = collectionViewContentSize.height - cachedGlobalFooterSize.height

//            if globalFooter.pinsToBounds, collectionView.bounds.maxY > collectionViewContentSize.height {
//                frame.size.height += collectionView.bounds.maxY - collectionViewContentSize.height
//            }
//
//            if !globalFooter.pinsToContent, globalFooter.pinsToBounds, collectionView.bounds.maxY > collectionViewContentSize.height {
//                frame.origin.y += collectionView.bounds.maxY - collectionViewContentSize.height
//            }

            return (frame, 300)
        case UICollectionView.elementKindSectionHeader:
            var frame = attributes.frame
            frame.origin.y += adjustedOrigin + cachedGlobalHeaderSize.height + globalHeader.inset
            return (frame, 200)
        case UICollectionView.elementKindSectionFooter:
            let frame = attributes.frame.offsetBy(dx: 0, dy: adjustedOrigin + cachedGlobalHeaderSize.height + globalHeader.inset)
            return (frame, 100)
        default:
            let frame = attributes.frame.offsetBy(dx: 0, dy: adjustedOrigin + cachedGlobalHeaderSize.height + globalHeader.inset)
            return (frame, attributes.zIndex)
        }
    }

}

private extension FlowLayout {

    private var isNavigationBarHidden: Bool {
         return collectionView?.owningViewController?.navigationController?.navigationBar.isHidden == true
    }

    private var isTabBarHidden: Bool {
        return collectionView?.owningViewController?.tabBarController?.tabBar.isHidden == true
    }

}

private extension UIView {

    @objc var owningViewController: UIViewController? {
        var responder: UIResponder? = self

        while !(responder is UIViewController) && superview != nil {
            if let next = responder?.next {
                responder = next
            }
        }

        return responder as? UIViewController
    }

}
