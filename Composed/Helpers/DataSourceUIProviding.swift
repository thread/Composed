public struct DataSourceUISectionMetrics {

    public let insets: UIEdgeInsets
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat

    public init(insets: UIEdgeInsets, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        self.insets = insets
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

}

public protocol DataSourceUILifecycleObserving {

    /// Called when the dataSource is initially prepared. Its generally only called once per lifecycle
    func prepare()

    /// Called whenever the dataSource becomes active, after being inactive
    func didBecomeActive()

    /// Called whenever the dataSource resigns active, after being active
    func willResignActive()

}

extension DataSourceUILifecycleObserving {
    public func prepare() { }
    public func didBecomeActive() { }
    public func willResignActive() { }
}

public struct DataSourceUISizingContext {
    public let prototype: UICollectionReusableView
    public let indexPath: IndexPath
    public let layoutSize: CGSize
    public let metrics: DataSourceUISectionMetrics
}

public protocol DataSourceUISizingStrategy {
    func size(forElementAt indexPath: IndexPath, context: DataSourceUISizingContext, dataSource: DataSource) -> CGSize
}

public protocol DataSourceUIProviding {
    func sizingStrategy() -> DataSourceUISizingStrategy
    func metrics(for section: Int) -> DataSourceUISectionMetrics
    func cellConfiguration(for indexPath: IndexPath) -> DataSourceUIConfiguration
    func headerConfiguration(for section: Int) -> DataSourceUIConfiguration?
    func footerConfiguration(for section: Int) -> DataSourceUIConfiguration?
    func backgroundViewClass(for section: Int) -> UICollectionReusableView.Type?
}

public extension DataSourceUIProviding {
    func headerConfiguration(for section: Int) -> DataSourceUIConfiguration? { return nil }
    func footerConfiguration(for section: Int) -> DataSourceUIConfiguration? { return nil }
    func backgroundViewClass(for section: Int) -> UICollectionReusableView.Type? { return nil }
}

open class ColumnSizingStrategy: DataSourceUISizingStrategy {

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

    open func size(forElementAt indexPath: IndexPath, context: DataSourceUISizingContext, dataSource: DataSource) -> CGSize {
        return size(forElementAt: indexPath, context: context, dataSource: dataSource, columnCount: columnCount)
    }

    open func size(forElementAt indexPath: IndexPath, context: DataSourceUISizingContext, dataSource: DataSource, columnCount: Int) -> CGSize {
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
