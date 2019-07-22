import UIKit

open class CarouselSizingStrategy: CollectionUISizingStrategy {
    
    public enum SizingMode {
        /// Embedded cells will all have the same size and the
        /// carousel will be sized according to this size and
        /// the first section's metrics
        case fixedSize(CGSize)
        
        /// Embedded cells will all have the same width, but
        /// can have dynamic heights. The size of the carousel
        /// will be calculated by sizing every cell in the embedded
        /// data source. For large data sets this can be very expensive.
        case fixedWidth(CGFloat)
        
        /// Embedded cells will all have fixed heights, but can
        /// have dynamic widths. The size of the carousel will
        /// be fixed to this height plus the first secion's metrics
        case fixedHeight(CGFloat)
        
        /// Embedded cells will be automatically sized. If `isUniform`
        /// is `true` only the first cell will be sized and the carousel's
        /// size will be calculated from this cell. If `isUniform` is
        /// `false` all cells will be sized and the one with bigest height
        /// will be used. For large data sets this can expensive.
        case automatic(isUniform: Bool)
    }

    public let sizingMode: SizingMode
    
    private var cachedSizes: [IndexPath: CGSize] = [:]

    public init(sizingMode: SizingMode) {
        self.sizingMode = sizingMode
    }

    public func cachedSize(forElementAt indexPath: IndexPath) -> CGSize? {
        switch sizingMode {
        case let .fixedSize(size):
            return size
        case .fixedWidth, .fixedHeight:
            return cachedSizes[indexPath]
        case let .automatic(isUniform):
            if isUniform, let knownSize = cachedSizes.values.first {
                return knownSize
            } else {
                return cachedSizes[indexPath]
            }
        }
    }

    public func size(forElementAt indexPath: IndexPath, context: CollectionUISizingContext, dataSource: DataSource) -> CGSize {
        if let size = cachedSize(forElementAt: indexPath) { return size }
        
        let targetView: UIView
        if let cell = context.prototype as? UICollectionViewCell {
            targetView = cell.contentView
        } else {
            targetView = context.prototype
        }
        
        let size: CGSize
        switch sizingMode {
        case let .fixedSize(size):
            return size
        case let .fixedWidth(width):
            let targetSize = CGSize(width: width, height: 0)
            size = targetView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        case let .fixedHeight(height):
            let targetSize = CGSize(width: 0, height: height)
            size = targetView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .required)
        case .automatic:
            size = targetView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        }

        cachedSizes[indexPath] = size
        return size
    }

}
