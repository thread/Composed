import UIKit

public struct GlobalAttributes {

    public var pinsToBounds: Bool = true
    public var pinsToContent: Bool = false
    public var prefersFollowContent: Bool = false

    public var inset: CGFloat = 0
    public var layoutFromSafeArea: Bool = true

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
        size.height += adjustedGlobalFooterSize.height + globalFooter.inset
        return size
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let originalAttributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? FlowLayoutAttributes

        let count = collectionView!.numberOfItems(inSection: indexPath.section)
        originalAttributes?.isFirstInSection = indexPath.item == 0
        originalAttributes?.isLastInSection = indexPath.item == count - 1

        guard requiresLayout else { return originalAttributes }

        originalAttributes.map {
            ($0.frame, $0.zIndex) = adjusted(frame: $0.frame,
                                             zIndex: $0.zIndex,
                                             for: $0.representedElementKind)
        }

        return originalAttributes
    }

    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let originalAttributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)?.copy() as? UICollectionViewLayoutAttributes
        guard requiresLayout else { return originalAttributes }

        switch elementKind {
        case UICollectionView.elementKindGlobalHeader:
            let attributes = FlowLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
            attributes.frame = CGRect(origin: .zero, size: cachedGlobalHeaderSize)
            (attributes.frame, attributes.zIndex) = adjusted(frame: attributes.frame, zIndex: attributes.zIndex, for: attributes.representedElementKind)
            attributes.zIndex = 300
            return attributes
        case UICollectionView.elementKindGlobalFooter:
            let attributes = FlowLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
            attributes.frame = CGRect(origin: .zero, size: cachedGlobalFooterSize)
            (attributes.frame, attributes.zIndex) = adjusted(frame: attributes.frame, zIndex: attributes.zIndex, for: attributes.representedElementKind)
            return attributes
        default:
            originalAttributes.map {
                ($0.frame, $0.zIndex) = adjusted(frame: $0.frame,
                                                 zIndex: $0.zIndex,
                                                 for: $0.representedElementKind)
            }

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

        guard let delegate = collectionView?.delegate as? FlowLayoutDelegate else { return nil }

        let metrics = self.metrics(forSection: indexPath.section, delegate: delegate)
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

        let rect = rect.insetBy(dx: 0, dy: -(adjustedGlobalHeaderSize.height + adjustedGlobalFooterSize.height))
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
            attributes?.forEach {
                ($0.frame, $0.zIndex) = adjusted(frame: $0.frame,
                                                 zIndex: $0.zIndex,
                                                 for: $0.representedElementKind)

            }

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

    // MARK: Scroll position restoration

    private var firstVisibleIndexPath: IndexPath?

    open override func prepare(forAnimatedBoundsChange oldBounds: CGRect) {
        super.prepare(forAnimatedBoundsChange: oldBounds)
        saveContentOffset()
    }

    open override func finalizeAnimatedBoundsChange() {
        super.finalizeAnimatedBoundsChange()
        firstVisibleIndexPath = nil
    }

    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let offset = restoredContentOffset() else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        return offset
    }

    public func saveContentOffset() {
        firstVisibleIndexPath = collectionView?.indexPathsForVisibleItems.sorted().first
    }

    public func restoredContentOffset() -> CGPoint? {
        guard let collectionView = collectionView,
            let indexPath = firstVisibleIndexPath,
            let attributes = layoutAttributesForItem(at: indexPath) else {
                return nil
        }

        return CGPoint(x: attributes.frame.minX - collectionView.contentInset.left,
                       y: attributes.frame.minY - collectionView.contentInset.top)
    }

}

private extension FlowLayout {

    var additionalContentInset: CGFloat {
        guard cachedGlobalHeaderSize != .zero, let collectionView = collectionView else { return 0 }
        guard globalHeader.layoutFromSafeArea else { return 0 }
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
            return safeAreaAdjustment
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
        adjustedSize.height += globalHeader.layoutFromSafeArea ? 0 : collectionView.safeAreaInsets.top
        return adjustedSize
    }

    var adjustedGlobalFooterOrigin: CGPoint {
        guard cachedGlobalFooterSize != .zero else { return .zero }
        var adjustedOrigin = CGPoint.zero
        adjustedOrigin.y += collectionViewContentSize.height - adjustedGlobalFooterSize.height
        return adjustedOrigin
    }

    var adjustedGlobalFooterSize: CGSize {
        guard cachedGlobalFooterSize != .zero, let collectionView = collectionView else { return .zero }
        var adjustedSize = cachedGlobalFooterSize
        adjustedSize.height += globalFooter.layoutFromSafeArea ? 0 : collectionView.safeAreaInsets.bottom
        return cachedGlobalFooterSize
    }

    var adjustedOrigin: CGPoint {
        guard cachedGlobalHeaderSize != .zero else { return .zero }
        var origin = adjustedGlobalHeaderOrigin
        origin.y += adjustedGlobalHeaderSize.height + globalHeader.inset
        return origin
    }

    var adjustedHeaderContentOffset: CGPoint {
        guard let collectionView = collectionView else { return .zero }
        var contentOffset = collectionView.contentOffset
        contentOffset.y += collectionView.adjustedContentInset.top
        return contentOffset
    }

    var adjustedFooterContentOffset: CGPoint {
        guard let collectionView = collectionView else { return .zero }
        var contentOffset = CGPoint(x: 0, y: collectionView.bounds.maxY - collectionViewContentSize.height)
        contentOffset.y -= collectionView.adjustedContentInset.bottom
        return contentOffset
    }

    func adjusted(frame: CGRect, zIndex: Int, for kind: String?) -> (frame: CGRect, zIndex: Int) {
        switch kind {
        case UICollectionView.elementKindGlobalHeader:
            var frame = frame
            frame.origin = adjustedGlobalHeaderOrigin
            frame.size = adjustedGlobalHeaderSize

            if globalHeader.pinsToBounds {
                let offset = adjustedHeaderContentOffset

                if globalHeader.prefersFollowContent, offset.y > 0 {
                    // do nothing
                } else {
                    frame.origin.y += offset.y
                }

                if globalHeader.pinsToContent, offset.y < 0 {
                    frame.size.height -= offset.y
                }
            }

            return (frame, UICollectionView.globalHeaderZIndex)
        case UICollectionView.elementKindGlobalFooter:
            guard let collectionView = collectionView else { return (frame, zIndex) }

            var frame = frame
            frame.origin = adjustedGlobalFooterOrigin
            frame.size = adjustedGlobalFooterSize

            if globalFooter.pinsToBounds {
                let offset = adjustedFooterContentOffset

                if globalFooter.prefersFollowContent, offset.y < 0 {
                    // do nothing
                } else {
                    frame.origin.y += offset.y
                }

                if globalFooter.pinsToContent, offset.y > 0 {
                    frame.origin.y -= offset.y
                    frame.size.height += offset.y
                }
            }

            frame.size.height += globalFooter.layoutFromSafeArea ? 0 : collectionView.safeAreaInsets.bottom

            return (frame, UICollectionView.globalFooterZIndex)
        case UICollectionView.elementKindSectionHeader:
            return (frame.offsetBy(dx: 0, dy: adjustedOrigin.y), UICollectionView.sectionHeaderZIndex)
        case UICollectionView.elementKindSectionFooter:
            return (frame.offsetBy(dx: 0, dy: adjustedOrigin.y), UICollectionView.sectionFooterZIndex)
        default:
            return (frame.offsetBy(dx: 0, dy: adjustedOrigin.y), zIndex)
        }
    }

}

private extension FlowLayout {

    var requiresLayout: Bool {
        return cachedGlobalHeaderSize.height != 0 || cachedGlobalFooterSize.height != 0
    }

}
