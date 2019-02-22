import UIKit

public struct GlobalAttributes {

    public var pinsToBounds: Bool = true
    public var pinsToContent: Bool = false
    public var prefersFollowContent: Bool = true

    public var inset: CGFloat = 0
    public var respectSafeAreaForPosition: Bool = true
    public var respectSafeAreaForSize: Bool = false

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

    private var cachedGlobalHeaderSize: CGSize = .zero
    private var cachedGlobalFooterSize: CGSize = .zero
    private var backgroundViewClasses: [Int: UICollectionReusableView.Type] = [:]

    open override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }

        for section in 0..<collectionView.numberOfSections {
            guard let backgroundViewClass = (collectionView.delegate as? FlowLayoutDelegate)?
                .backgroundViewClass?(in: collectionView, forSectionAt: section) else { continue }
            register(backgroundViewClass, forDecorationViewOfKind: String(describing: backgroundViewClass))
        }

        if cachedGlobalHeaderSize == .zero {
            cachedGlobalHeaderSize = sizeForGlobalHeader
        }

        if cachedGlobalFooterSize == .zero {
            cachedGlobalFooterSize = sizeForGlobalFooter
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
        size.height += adjustedOrigin.y
        return size
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let originalAttributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? FlowLayoutAttributes

        let count = collectionView!.numberOfItems(inSection: indexPath.section)
        originalAttributes?.isFirstInSection = indexPath.item == 0
        originalAttributes?.isLastInSection = indexPath.item == count - 1

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
            attributes.zIndex = 300
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

    open override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let firstIndex = 0
        let lastIndex = collectionView!.numberOfItems(inSection: indexPath.section) - 1
        guard lastIndex >= 0 else { return nil }

        guard let firstAttributes = layoutAttributesForItem(at: IndexPath(item: firstIndex, section: indexPath.section)),
            let lastAttributes = layoutAttributesForItem(at: IndexPath(item: lastIndex, section: indexPath.section)) else {
                return nil
        }

        let metrics = self.metrics(forSection: indexPath.section, delegate: collectionView!.delegate as! FlowLayoutDelegate)
        let bgAttributes = FlowLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)

        let x = metrics.insets.left
        let y = firstAttributes.frame.minY
        let w = collectionView!.bounds.width - (metrics.insets.left + metrics.insets.right)
        let h = lastAttributes.frame.maxY - firstAttributes.frame.minY

        bgAttributes.frame = CGRect(x: x, y: y, width: w, height: h)
        bgAttributes.zIndex = -100

        return bgAttributes
    }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView else { return nil }

        let rect = rect.insetBy(dx: 0, dy: -(cachedGlobalHeaderSize.height + cachedGlobalFooterSize.height))
        let originalAttributes = super.layoutAttributesForElements(in: rect) ?? []

        originalAttributes.lazy
            .filter { $0.representedElementCategory == .cell }
            .compactMap { $0 as? FlowLayoutAttributes }
            .forEach {
                let count = collectionView.numberOfItems(inSection: $0.indexPath.section)
                $0.isFirstInSection = $0.indexPath.item == 0
                $0.isLastInSection = $0.indexPath.item == count - 1
        }

        var attributes = NSArray(array: originalAttributes, copyItems: true) as? [UICollectionViewLayoutAttributes]

        func appendBackgroundViews() {
            for section in 0..<collectionView.numberOfSections {
                guard let backgroundViewClass = (collectionView.delegate as? FlowLayoutDelegate)?
                    .backgroundViewClass?(in: collectionView, forSectionAt: section) else { continue }

                let indexPath = IndexPath(item: 0, section: section)

                guard let attr = layoutAttributesForDecorationView(ofKind: String(describing: backgroundViewClass), at: indexPath),
                    rect.intersects(attr.frame) else {
                        continue
                }

                attributes?.append(attr)
            }
        }

        if !requiresLayout {
            // if we don't have any global elements we can just add the background views now
            appendBackgroundViews()
            return attributes
        } else {
            // otherwise we need to adjust the frames first
            attributes?.forEach { ($0.frame, $0.zIndex) = adjustedFrame(for: $0) }
            appendBackgroundViews()

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

            backgroundViewClasses.enumerated().forEach {
                let kind = String(describing: $0.element.value)
                let indexPath = IndexPath(item: 0, section: $0.offset)
                context.invalidateDecorationElements(ofKind: kind, at: [indexPath])
            }
        }

        return context
    }

}

private extension FlowLayout {

    var additionalContentInset: CGFloat {
        guard cachedGlobalHeaderSize != .zero, let collectionView = collectionView else { return 0 }
        let safeAreaAdjustment = collectionView.adjustedContentInset.top - collectionView.contentInset.top

        switch collectionView.contentInsetAdjustmentBehavior {
        case .never:
            let isTopBarHidden = safeAreaAdjustment != collectionView.safeAreaInsets.top

            if isTopBarHidden {
                return collectionView.safeAreaInsets.top
            } else {
                return collectionView.adjustedContentInset.top
            }
        default:
            let isTopBarHidden = safeAreaAdjustment == collectionView.safeAreaInsets.top

            if isTopBarHidden {
                return collectionView.adjustedContentInset.top
            } else {
                return collectionView.safeAreaInsets.top
            }
        }
    }

    var adjustedGlobalHeaderOrigin: CGPoint {
        guard cachedGlobalHeaderSize != .zero, let collectionView = collectionView else { return .zero }
        var adjustedOrigin = CGPoint.zero
        adjustedOrigin.y += additionalContentInset
        adjustedOrigin.y -= collectionView.adjustedContentInset.top
        return adjustedOrigin
    }

    var adjustedGlobalHeaderSize: CGSize {
        guard cachedGlobalHeaderSize != .zero, let collectionView = collectionView else { return .zero }
        var adjustedSize = cachedGlobalHeaderSize
        adjustedSize.height += globalHeader.respectSafeAreaForSize ? collectionView.safeAreaInsets.top : 0
        return adjustedSize
    }

    var adjustedOrigin: CGPoint {
        guard cachedGlobalHeaderSize != .zero else { return .zero }
        var origin = adjustedGlobalHeaderOrigin
        origin.y += adjustedGlobalHeaderSize.height + globalHeader.inset
        return origin
    }

    var adjustedContentOffset: CGPoint {
        guard let collectionView = collectionView else { return .zero }
        var contentOffset = collectionView.contentOffset
        contentOffset.y += collectionView.adjustedContentInset.top
        return contentOffset
    }

    func adjustedFrame(for attributes: UICollectionViewLayoutAttributes) -> (frame: CGRect, zIndex: Int) {
        guard let collectionView = collectionView else { return (attributes.frame, attributes.zIndex) }

        switch attributes.representedElementKind {
        case UICollectionView.elementKindGlobalHeader:
            var frame = attributes.frame
            frame.origin = adjustedGlobalHeaderOrigin
            frame.size = adjustedGlobalHeaderSize

            if globalHeader.pinsToBounds {
                let offset = adjustedContentOffset

                if globalHeader.prefersFollowContent, offset.y < 0 {
                    // do nothing
                } else {
                    frame.origin.y += offset.y
                }

//                if globalHeader.pinsToContent, offset.y < 0 {
//                    frame.size.height -= offset.y
//                }

//                if globalHeader.pinsToContent, collectionView.contentOffset.y < -collectionView.safeAreaInsets.top {
//                    frame.size.height = max(cachedGlobalHeaderSize.height, cachedGlobalHeaderSize.height - frame.minY + adjustedHeaderOrigin)
//                }
            }

            return (frame, UICollectionView.globalHeaderZIndex)
//        case UICollectionView.elementKindGlobalFooter:
//            var frame = attributes.frame
//            let offset = collectionView.bounds.maxY - collectionView.safeAreaInsets.bottom - collectionViewContentSize.height
//
//            if globalFooter.respectSafeAreaForPosition {
//                frame.origin.y = collectionViewContentSize.height - cachedGlobalFooterSize.height
//            } else {
//                frame.origin.y = max(collectionViewContentSize.height, collectionView.bounds.maxY - adjustedFooterOrigin)
//                    - cachedGlobalFooterSize.height + adjustedFooterOrigin
//            }
//
//            if globalFooter.pinsToBounds {
//                if globalFooter.prefersFollowContent, offset < 0 {
//                    // do nothing
//                } else {
//                    frame.origin.y += offset
//                }
//            }
//
//            if globalFooter.pinsToBounds
//                && globalFooter.pinsToContent
//                && offset > 0 {
//                if collectionViewContentSize.height > collectionView.bounds.height {
//                    frame.origin.y -= offset
//                }
//
//                frame.size.height += offset
//            }
//
//            return (frame, UICollectionView.globalFooterZIndex)
//        case UICollectionView.elementKindSectionHeader:
//            var frame = attributes.frame
//            frame.origin.y += adjustedHeaderOrigin
//            return (frame, UICollectionView.sectionHeaderZIndex)
//        case UICollectionView.elementKindSectionFooter:
//            let frame = attributes.frame.offsetBy(dx: 0, dy: adjustedHeaderOrigin + cachedGlobalHeaderSize.height + globalHeader.inset)
//            return (frame, UICollectionView.sectionFooterZIndex)
        default:
            let frame = attributes.frame.offsetBy(dx: 0, dy: adjustedOrigin.y)
            return (frame, attributes.zIndex)
        }
    }

}

private extension FlowLayout {

    var requiresLayout: Bool {
        return cachedGlobalHeaderSize.height != 0 || cachedGlobalFooterSize.height != 0
    }

}
