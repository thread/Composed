import UIKit

public struct GlobalAttributes {

    public enum PinningBehaviour {
        case alwaysVisible // remains on screen
        case prefersFollowContent // visible when contentOffset.y <= 0, otherwise follow content off-screen
    }

    public var pinsToBounds: Bool = true
    public var pinsToContent: Bool = true

    public var inset: CGFloat = 0
    public var maxHeight: CGFloat = .greatestFiniteMagnitude

    public var insetReference: UICollectionViewFlowLayout.SectionInsetReference = .fromContentInset
    public var pinningBehaviour: PinningBehaviour = .alwaysVisible

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
        globalFooter.pinsToContent = false
    }

    open override var collectionViewContentSize: CGSize {
        var size = super.collectionViewContentSize
        size.height += sizeForGlobalHeader.height
        size.height += sizeForGlobalFooter.height
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
            attributes.frame = CGRect(origin: .zero, size: sizeForGlobalHeader)
            (attributes.frame, attributes.zIndex) = adjustedFrame(for: attributes)
            return attributes
        case UICollectionView.elementKindGlobalFooter:
            let attributes = FlowLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
            attributes.frame = CGRect(origin: .zero, size: sizeForGlobalFooter)
            (attributes.frame, attributes.zIndex) = adjustedFrame(for: attributes)
            return attributes
        default:
            originalAttributes.map { ($0.frame, $0.zIndex) = adjustedFrame(for: $0) }
            return originalAttributes
        }
    }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = NSArray(array: super.layoutAttributesForElements(in: rect) ?? [], copyItems: true) as? [UICollectionViewLayoutAttributes]
        guard requiresLayout else { return attributes }

        attributes?.forEach { ($0.frame, $0.zIndex) = adjustedFrame(for: $0) }

        if sizeForGlobalHeader.height > 0,
            let header = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindGlobalHeader,
                                                              at: UICollectionView.globalElementIndexPath) {
            attributes?.append(header)
        }

        if sizeForGlobalFooter.height > 0,
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
            if sizeForGlobalHeader.height > 0 {
                context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindGlobalHeader, at: [UICollectionView.globalElementIndexPath])
            }

            if sizeForGlobalFooter.height > 0 {
                context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindGlobalFooter, at: [UICollectionView.globalElementIndexPath])
            }
        }

        return context
    }

}

private extension FlowLayout {

    func adjustedFrame(for attributes: UICollectionViewLayoutAttributes) -> (frame: CGRect, zIndex: Int) {
        guard let collectionView = collectionView else { return (attributes.frame, 0) }
        let globalHeaderSize = sizeForGlobalHeader

        switch attributes.representedElementKind {
        case UICollectionView.elementKindGlobalHeader:
            var frame = attributes.frame

            if globalHeader.pinsToBounds {
                switch globalHeader.pinningBehaviour {
                case .prefersFollowContent where collectionView.contentOffset.y >= 0:
                    break // do nothing
                default:
                    frame.origin.y += collectionView.contentOffset.y
                }

                switch globalHeader.insetReference {
                case .fromSafeArea:
                    frame.origin.y += collectionView.safeAreaInsets.top
                case .fromContentInset:
                    frame.origin.y += collectionView.adjustedContentInset.top
                case .fromLayoutMargins:
                    frame.origin.y += collectionView.layoutMargins.top
                }
            }

            if globalHeader.pinsToContent, collectionView.contentOffset.y < 0 {
                frame.size.height = max(globalHeaderSize.height, globalHeaderSize.height - frame.minY)
                frame.size.height = min(frame.size.height, globalHeader.maxHeight)
            }

            return (frame, 1000)
        case UICollectionView.elementKindGlobalFooter:
            let globalFooterSize = sizeForGlobalFooter
            var frame = attributes.frame

            frame.origin.y = collectionViewContentSize.height - globalFooterSize.height + globalFooter.inset

            if globalFooter.pinsToBounds, collectionView.bounds.maxY > collectionViewContentSize.height {
                frame.size.height += collectionView.bounds.maxY - collectionViewContentSize.height
            }

            if !globalFooter.pinsToContent, globalFooter.pinsToBounds, collectionView.bounds.maxY > collectionViewContentSize.height {
                frame.origin.y += collectionView.bounds.maxY - collectionViewContentSize.height
            }

            return (frame, 999)
        case UICollectionView.elementKindSectionHeader:
            var frame = attributes.frame
            frame.origin.y += globalHeaderSize.height + globalHeader.inset

            if !globalHeader.pinsToBounds {
                frame.origin.y += collectionView.contentOffset.y - collectionView.safeAreaInsets.top
                frame.origin.y = max(attributes.frame.minY, globalHeaderSize.height)
            }

            return (frame, 1)
        default:
            let frame = attributes.frame.offsetBy(dx: 0, dy: globalHeaderSize.height + globalHeader.inset)
            return (frame, attributes.indexPath.item)
        }
    }

}
