import UIKit

open class CarouselSizingStrategy: CollectionUISizingStrategy {

    public let width: CGFloat
    private var cachedSize: CGSize?

    public init(width: CGFloat) {
        self.width = width
    }

    public func cachedSize(forElementAt indexPath: IndexPath) -> CGSize? {
        return cachedSize
    }

    public func size(forElementAt indexPath: IndexPath, context: CollectionUISizingContext, dataSource: DataSource) -> CGSize {
        if let size = cachedSize { return size }

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

        cachedSize = size
        return size
    }

}
