import UIKit

open class HeaderLayoutStrategy: NSObject {

    private let prototype: DataSourceHeaderView

    public init(prototype: DataSourceHeaderView) {
        self.prototype = prototype
    }

    public func headerSize(in section: Int, in layout: UICollectionViewLayout) -> CGSize {
        let width = layout.collectionView?.bounds.width ?? 0
        let target = CGSize(width: width, height: 0)
        return prototype.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
    }

}

open class FlowLayoutColumnStrategy: NSObject, FlowLayoutStrategy {

    public var layout: UICollectionViewLayout?
    public let columns: Int
    public let sectionInsets: UIEdgeInsets
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat

    public let headerStrategy: HeaderLayoutStrategy?
    private let prototype: DataSourceCell
    private var cachedSizes: [IndexPath: CGSize] = [:]

    public init(columns: Int = 1, sectionInsets: UIEdgeInsets = .zero, horizontalSpacing: CGFloat = 0, verticalSpacing: CGFloat = 0, prototype: DataSourceCell, headerStrategy: HeaderLayoutStrategy? = nil) {
        self.headerStrategy = headerStrategy
        self.prototype = prototype
        self.columns = columns
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.sectionInsets = sectionInsets
    }

    public func insets(in section: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    public func horizontalSpacing(in section: Int) -> CGFloat {
        return horizontalSpacing
    }

    public func verticalSpacing(in section: Int) -> CGFloat {
        return verticalSpacing
    }

    public func prototypeCell(for indexPath: IndexPath) -> DataSourceCell {
        return prototype
    }

    public func size(forCell: DataSourceCell, at indexPath: IndexPath, in layout: UICollectionViewFlowLayout) -> CGSize {
        if let size = cachedSizes[indexPath] { return size }
        guard let delegate = layout.collectionView?.delegate as? UICollectionViewDelegateFlowLayout else { return .zero }

        let width = layout.columnWidth(forColumnCount: columns, inSection: indexPath.section, delegate: delegate)
        let target = CGSize(width: width, height: 0)
        let prototype = prototypeCell(for: indexPath)
        let size = prototype.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        cachedSizes[indexPath] = size

        return size
    }

    public func invalidate(indexPath: IndexPath) {
        cachedSizes[indexPath] = nil
    }

    public func invalidateAll() {
        cachedSizes.removeAll()
    }

}
