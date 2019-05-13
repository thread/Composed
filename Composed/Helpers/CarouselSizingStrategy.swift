import UIKit

open class CarouselSizingStrategy: CollectionUISizingStrategy {
    
    public enum SizingMode {
        case fixed(size: CGSize)
        case automatic(isUniform: Bool)
    }

    public let sizingMode: SizingMode
    
    private var cachedSizes: [IndexPath: CGSize] = [:]

    public init(sizingMode: SizingMode) {
        self.sizingMode = sizingMode
    }

    public func cachedSize(forElementAt indexPath: IndexPath) -> CGSize? {
        switch sizingMode {
        case let .fixed(size):
            return size
        case let .automatic(isUniform):
            if isUniform, let knownSize = cachedSizes.values.first {
                return knownSize
            } else if let cachedSize = cachedSizes[indexPath] {
                return cachedSize
            } else {
                return nil
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
            
        let size = targetView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        cachedSizes[indexPath] = size
        return size
    }

}
