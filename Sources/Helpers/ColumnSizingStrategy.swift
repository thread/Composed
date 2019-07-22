import UIKit

open class ColumnSizingStrategy: CollectionUISizingStrategy {

    public enum SizingMode {
        case fixed(height: CGFloat)
        case automatic(isUniform: Bool)
    }

    public let columnCount: Int
    public private(set) var sizingMode: SizingMode

    private var cachedSizes: [IndexPath: CGSize] = [:]

    public init(columnCount: Int, sizingMode: SizingMode) {
        self.columnCount = columnCount
        self.sizingMode = sizingMode
    }

    public func cachedSize(forElementAt indexPath: IndexPath) -> CGSize? {
        switch sizingMode {
        case .fixed:
            return cachedSizes.values.first
        case let .automatic(isUniform):
            return isUniform ? cachedSizes.values.first : cachedSizes[indexPath]
        }
    }

    open func size(forElementAt indexPath: IndexPath, context: CollectionUISizingContext, dataSource: DataSource) -> CGSize {
        return size(forElementAt: indexPath, context: context, dataSource: dataSource, columnCount: columnCount)
    }

    open func size(forElementAt indexPath: IndexPath, context: CollectionUISizingContext, dataSource: DataSource, columnCount: Int) -> CGSize {
        if let size = cachedSizes[indexPath] { return size }

        var width: CGFloat {
            let interitemSpacing = CGFloat(columnCount - 1) * context.metrics.horizontalSpacing
            let availableWidth = context.layoutSize.width - context.metrics.insets.left - context.metrics.insets.right - interitemSpacing
            return (availableWidth / CGFloat(columnCount)).rounded(.down)
        }

        switch sizingMode {
        case let .fixed(height):
            let size = CGSize(width: width, height: height)
            cachedSizes[indexPath] = size
            return size
        case let .automatic(isUniform):
            if isUniform, let size = cachedSizes.values.first {
                cachedSizes[indexPath] = size
                return size
            }

            let targetView: UIView
            let targetSize = CGSize(width: width, height: 0)

            if let cell = context.prototype as? UICollectionViewCell {
                targetView = cell.contentView
            } else {
                targetView = context.prototype
            }

            let size = targetView.systemLayoutSizeFitting(
                targetSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel)

            cachedSizes[indexPath] = size
            return size
        }
    }

}
