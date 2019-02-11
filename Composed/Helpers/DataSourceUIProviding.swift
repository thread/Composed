public typealias DataSourceUISizingClosure = (DataSourceUIInvalidationContext) -> CGSize

public struct DataSourceUIInvalidationContext {
    public let prototype: UICollectionReusableView
    public let indexPath: IndexPath
    public let layoutSize: CGSize
    public let metrics: DataSourceUISectionMetrics
}

public protocol DataSourceUISizingStrategy {
    func size(forElementAt indexPath: IndexPath, context: DataSourceUIInvalidationContext) -> CGSize
    func invalidate(elementsAt indexPaths: [IndexPath])
}

public protocol DataSourceUIProviding {
    var sizingStrategy: DataSourceUISizingStrategy { get }

    func metrics(for section: Int) -> DataSourceUISectionMetrics
    func cellConfiguration(for indexPath: IndexPath) -> DataSourceUICellConfiguration
    func headerConfiguration(for section: Int) -> DataSourceUIViewConfiguration?
    func footerConfiguration(for section: Int) -> DataSourceUIViewConfiguration?
}

public extension DataSourceUIProviding {
    var sizingStrategy: DataSourceUISizingStrategy { return ColumnSizingStrategy(columnCount: 1, sizingMode: .automatic(isUniform: true)) }
    func headerConfiguration(for section: Int) -> DataSourceUIViewConfiguration? { return nil }
    func footerConfiguration(for section: Int) -> DataSourceUIViewConfiguration? { return nil }
}

public final class ColumnSizingStrategy: DataSourceUISizingStrategy {

    public enum SizingMode {
        case fixed(height: CGFloat)
        case automatic(isUniform: Bool)
    }

    public let columnCount: Int
    public let sizingMode: SizingMode

    private var cachedSizes: [IndexPath: CGSize] = [:]

    public init(columnCount: Int, sizingMode: SizingMode) {
        self.columnCount = columnCount
        self.sizingMode = sizingMode
    }

    public func size(forElementAt indexPath: IndexPath, context: DataSourceUIInvalidationContext) -> CGSize {
        if let size = cachedSizes[indexPath] { return size }

        let interitemSpacing = CGFloat(columnCount - 1) * context.metrics.horizontalSpacing
        let availableWidth = context.layoutSize.width - context.metrics.insets.left - context.metrics.insets.right - interitemSpacing
        let width = (availableWidth / CGFloat(columnCount)).rounded(.down)

        switch sizingMode {
        case let .fixed(height):
            return CGSize(width: width, height: height)
        case let .automatic(isUniform):
            if let size = cachedSizes[indexPath] { return size }
            if isUniform, let size = cachedSizes.values.first { return size }

            let targetSize = CGSize(width: width, height: 0)
            let cell = context.prototype as! UICollectionViewCell
            let size = cell.contentView.systemLayoutSizeFitting(
                targetSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel)
            cachedSizes[indexPath] = size
            return size
        }
    }

    public func invalidate(elementsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { cachedSizes[$0] = nil }
    }

}
