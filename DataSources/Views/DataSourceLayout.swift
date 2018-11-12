import UIKit

@objc public enum DataSourceLayoutKind: Int {
    case `default`
    case alignedToLeading
}

@objc public protocol UICollectionViewDelegateDataSourceLayout: UICollectionViewDelegateFlowLayout {
    @objc func collectionView(_ collectionView: UICollectionView,
                              layout collectionViewLayout: UICollectionViewLayout,
                              layoutKindForSectionAt section: Int) -> DataSourceLayoutKind
}

open class DataSourceLayout: UICollectionViewFlowLayout {

    public struct Metrics {
        public static var zero: Metrics {
            return Metrics(headerHeight: 0, footerHeight: 0, insets: .zero, itemSpacing: 0, lineSpacing: 0)
        }

        public let headerHeight: CGFloat
        public let footerHeight: CGFloat
        public let insets: UIEdgeInsets
        public let itemSpacing: CGFloat
        public let lineSpacing: CGFloat
    }

    public struct Options {
        public var allowsGlobalHeader: Bool
        public var globalHeaderBehaviour: GlobalHeaderBehaviour
        public var headersPinToVisibleBounds: Bool
        public var footersPinToVisibleBounds: Bool

        public init(allowsGlobalHeader: Bool, globalHeaderBehaviour: GlobalHeaderBehaviour, headersPinToVisibleBounds: Bool, footersPinToVisibleBounds: Bool) {
            self.allowsGlobalHeader = allowsGlobalHeader
            self.globalHeaderBehaviour = globalHeaderBehaviour
            self.headersPinToVisibleBounds = headersPinToVisibleBounds
            self.footersPinToVisibleBounds = footersPinToVisibleBounds
        }
    }

    public enum GlobalHeaderBehaviour {
        case stretchy(maxHeight: CGFloat, pinsToBounds: Bool)
        case pinsToBounds
        case pinsToContent
    }

    open override class var layoutAttributesClass: AnyClass {
        return DataSourceLayoutAttributes.self
    }

    open override class var invalidationContextClass: AnyClass {
        return DataSourceLayoutInvalidationContext.self
    }

    public var options: Options

    var previousStretchFactor: CGFloat = 0

    public override init() {
        options = Options(allowsGlobalHeader: false,
                          globalHeaderBehaviour: .pinsToContent,
                          headersPinToVisibleBounds: false,
                          footersPinToVisibleBounds: false)

        super.init()

        sectionFootersPinToVisibleBounds = true
        sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? DataSourceLayoutAttributes else { return nil }
        guard layoutKind(inSection: indexPath.section) == .alignedToLeading else { return attributes }

        guard shouldLayout(in: attributes.indexPath.section) else { return attributes }
        guard attributes.indexPath.item > 0 else { return attributes }

        let previousIndexPath = IndexPath(item: attributes.indexPath.item - 1, section: attributes.indexPath.section)
        let previousAttributes = layoutAttributesForItem(at: previousIndexPath)!

        // lets check if these attributes are on the 'same line' as our previous attributes
        var frame = attributes.frame
        frame.origin.x = previousAttributes.frame.minX
        guard frame.intersects(previousAttributes.frame) else {
            // First item in row
            // This could be improved by checking if this is the _only_ item on this row
            // TODO: Not hardcode this
            attributes.frame.origin.x = 16
            return attributes
        }

        let metrics = self.metrics(forSection: indexPath.section, layoutDelegate: collectionView!.delegate as! UICollectionViewDelegateFlowLayout)
        attributes.frame.origin.x = previousAttributes.frame.maxX + metrics.itemSpacing

        return attributes
    }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = super.layoutAttributesForElements(in: rect) as? [DataSourceLayoutAttributes] ?? []

        guard !layoutAttributes.isEmpty else { return nil }

        for attributes in layoutAttributes where attributes.representedElementCategory == .cell {
            guard layoutKind(inSection: attributes.indexPath.section) == .alignedToLeading else { continue }
            guard let index = layoutAttributes.index(of: attributes) else { continue }
            layoutAttributes.remove(at: index)

            guard let attr = layoutAttributesForItem(at: attributes.indexPath) as? DataSourceLayoutAttributes else { continue }
            layoutAttributes.append(attr)
        }

        guard shouldAlwaysLayout else { return layoutAttributes }

        if let indexes = managedHeaderIndexes(in: rect) {
            for section in indexes {
                let indexPath = IndexPath(item: 0, section: section)

                if let attributes = super.layoutAttributesForSupplementaryView(ofKind:
                    UICollectionView.elementKindSectionHeader, at: indexPath) as? DataSourceLayoutAttributes {
                    layoutAttributes.append(attributes)
                }
            }

            for attributes in layoutAttributes
                where attributes.representedElementKind == UICollectionView.elementKindSectionHeader {
                    (attributes.frame, attributes.zIndex) = adjustedHeaderAttributes(for: attributes)
            }
        }

        return layoutAttributes
    }

    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard shouldAlwaysLayout else { return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath) }

        guard let attributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath) as? DataSourceLayoutAttributes else { return nil }

        (attributes.frame, attributes.zIndex) = adjustedHeaderAttributes(for: attributes)
        return attributes
    }

    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard shouldAlwaysLayout else { return super.shouldInvalidateLayout(forBoundsChange: newBounds) }
        return true
    }

    open override func invalidationContext(forBoundsChange newBounds: CGRect)
        -> UICollectionViewLayoutInvalidationContext {
            guard shouldAlwaysLayout,
                let invalidationContext = super.invalidationContext(forBoundsChange: newBounds)
                    as? UICollectionViewFlowLayoutInvalidationContext,
                let oldBounds = collectionView?.bounds
                else { return super.invalidationContext(forBoundsChange: newBounds) }

            if oldBounds.size != newBounds.size {
                invalidationContext.invalidateFlowLayoutDelegateMetrics = true
            }

            if oldBounds.origin != newBounds.origin {
                if let indexes = allHeaderIndexes(forRect: newBounds) {
                    let indexPaths = indexes.map { IndexPath(item: 0, section: $0) }
                    invalidationContext.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader, at: indexPaths)
                }
            }

            return invalidationContext
    }

}

private extension DataSourceLayout {

    var shouldAlwaysLayout: Bool {
        if case .pinsToBounds = options.globalHeaderBehaviour { return true }
        return options.allowsGlobalHeader
            || options.headersPinToVisibleBounds
            || options.footersPinToVisibleBounds
    }

    func shouldLayout(in section: Int) -> Bool {
        if layoutKind(inSection: section) != .default { return true }
        return shouldAlwaysLayout
    }

    func zIndex(forSection section: Int) -> Int {
        return section > 0 ? 100 : 200
    }

    // Given a rect, calculates indexes of all confined section headers
    // _including_ the custom headers
    func allHeaderIndexes(forRect rect: CGRect) -> Set<Int>? {
        guard let layoutAttributes = super.layoutAttributesForElements(in: rect)
            as? [DataSourceLayoutAttributes] else {return nil}

        var indexes = Set<Int>()
        for attributes in layoutAttributes
            where attributes.isHeaderVisible(pinsToSectionBounds: options.headersPinToVisibleBounds) {
                indexes.insert(attributes.indexPath.section)
        }

        if options.allowsGlobalHeader {
            indexes.insert(0)
        }

        return indexes
    }

    // Given a rect, calculates the indexes of confined custom section headers
    // _excluding_ the regular headers handled by UICollectionViewFlowLayout
    func managedHeaderIndexes(in rect: CGRect) -> Set<Int>? {
        guard let layoutAttributes = super.layoutAttributesForElements(in: rect),
            var indexes = allHeaderIndexes(forRect: rect)  else {return nil}

        for attributes in layoutAttributes
            where attributes.representedElementKind == UICollectionView.elementKindSectionHeader {
                indexes.remove((attributes.indexPath as NSIndexPath).section)
        }

        return indexes
    }

    // Adjusts layout attributes of section headers
    func adjustedHeaderAttributes(for attributes: DataSourceLayoutAttributes) -> (frame: CGRect, zIndex: Int) {
        guard let collectionView = collectionView else { return (CGRect.zero, 0) }

        let section = attributes.indexPath.section
        var frame = attributes.frame

        // 1. Establish the section boundaries:
        let (minY, maxY) = boundaryMetrics(for: attributes)

        // 2. Determine the height and insets of the first section,
        //    in case it's stretchable or serves as a global header
        let globalMetrics = firstSectionMetrics()

        // 3. If within the above boundaries, the section should follow content offset
        //   (adjusting a few more things along the way)
        var offset = collectionView.contentOffset.y

        if case .pinsToContent = options.globalHeaderBehaviour {
            // todo: hard coding values isn't ideal, but will work for now
            offset = max(0, offset + UIApplication.shared.statusBarFrame.height + 44)
            //            offset += collectionView.contentInset.top
        }
        //        else {
        //            offset = max(0, offset)
        //            offset += collectionView.adjustedContentInset.top
        //        }

        offset += collectionView.contentInset.top

        if section > 0 {
            if options.headersPinToVisibleBounds {
                if options.allowsGlobalHeader, globalHeaderPinsToBounds {
                    offset += globalMetrics.headerHeight
                }

                frame.origin.y = min(max(offset, minY), maxY)
            }
        } else {
            if case let .stretchy(maxHeight, _) = options.globalHeaderBehaviour {
                if offset < 0 {
                    // Stretchy header
                    if globalMetrics.headerHeight - offset < maxHeight {
                        frame.size.height = globalMetrics.headerHeight - offset
                        attributes.stretchFactor = abs(offset)
                        previousStretchFactor = attributes.stretchFactor
                    } else {
                        // need to limit the stretch height
                        frame.size.height = maxHeight
                        attributes.stretchFactor = previousStretchFactor
                    }

                    frame.origin.y += offset
                }
            } else if options.allowsGlobalHeader, globalHeaderPinsToBounds {
                // keeps the global header pinned to the top of the collectionView
                frame.origin.y += offset
            } else {
                frame.origin.y = min(max(offset, minY), maxY)
            }
        }

        return (frame, zIndex(forSection: section))
    }

    var globalHeaderPinsToBounds: Bool {
        switch options.globalHeaderBehaviour {
        case .pinsToContent, .pinsToBounds:
            return true
        case let .stretchy(_, pinsToBounds):
            return pinsToBounds
        }
    }

    func layoutKind(inSection section: Int) -> DataSourceLayoutKind {
        guard let collectionView = collectionView else { return .default }

        return (collectionView.delegate as? UICollectionViewDelegateDataSourceLayout)?
            .collectionView(collectionView, layout: self, layoutKindForSectionAt: section)
            ?? .default
    }

}

private extension DataSourceLayoutAttributes {

    func isHeaderVisible(pinsToSectionBounds: Bool) -> Bool {
        let isHeader = representedElementKind == UICollectionView.elementKindSectionHeader
        let isCellInPinnedSection = pinsToSectionBounds && representedElementCategory == .cell
        return isCellInPinnedSection || isHeader
    }

}
