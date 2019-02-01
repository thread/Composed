import UIKit

@objc public protocol FlowLayoutStrategy: NSObjectProtocol {
    var headerStrategy: HeaderLayoutStrategy? { get }

    func insets(in section: Int) -> UIEdgeInsets
    func horizontalSpacing(in section: Int) -> CGFloat
    func verticalSpacing(in section: Int) -> CGFloat

    func prototypeCell(for indexPath: IndexPath) -> DataSourceCell
    func size(forCell: DataSourceCell, at indexPath: IndexPath, in layout: UICollectionViewFlowLayout) -> CGSize

    func invalidate(indexPath: IndexPath)
    func invalidateAll()
}

internal final class FlowLayoutNoStrategy: NSObject, FlowLayoutStrategy {
    var layout: UICollectionViewLayout?
    var headerStrategy: HeaderLayoutStrategy?

    func insets(in section: Int) -> UIEdgeInsets { return .zero }
    func horizontalSpacing(in section: Int) -> CGFloat { return 0 }
    func verticalSpacing(in section: Int) -> CGFloat { return 0 }
    func prototypeCell(for indexPath: IndexPath) -> DataSourceCell { fatalError("") }
    func size(forCell: DataSourceCell, at indexPath: IndexPath, in layout: UICollectionViewFlowLayout) -> CGSize { return .zero }
    func invalidate(indexPath: IndexPath) { }
    func invalidateAll() { }
}

open class HeaderLayoutStrategy: NSObject {

    private let prototypeHeader: DataSourceHeaderView

    public init(prototypeHeader: DataSourceHeaderView) {
        self.prototypeHeader = prototypeHeader
    }

    public func headerSize(in section: Int, in layout: UICollectionViewLayout) -> CGSize {
        let width = layout.collectionView?.bounds.width ?? 0
        let target = CGSize(width: width, height: 0)
        return prototypeHeader.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
    }

}

open class FlowLayoutColumnsStrategy<CellType>: NSObject, FlowLayoutStrategy where CellType: DataSourceCell {

    public var layout: UICollectionViewLayout?
    public let columns: Int
    public let metrics: FlowLayoutSectionMetrics

    public let headerStrategy: HeaderLayoutStrategy?
    private let prototypeCell: CellType
    private var cachedSizes: [IndexPath: CGSize] = [:]

    public init(columns: Int = 1, metrics: FlowLayoutSectionMetrics, prototypeCell: CellType, headerStrategy: HeaderLayoutStrategy? = nil) {
        self.headerStrategy = headerStrategy
        self.prototypeCell = prototypeCell
        self.columns = columns
        self.metrics = metrics
    }

    public func insets(in section: Int) -> UIEdgeInsets {
        return metrics.insets
    }

    public func horizontalSpacing(in section: Int) -> CGFloat {
        return metrics.horizontalSpacing
    }

    public func verticalSpacing(in section: Int) -> CGFloat {
        return metrics.verticalSpacing
    }

    public func prototypeCell(for indexPath: IndexPath) -> DataSourceCell {
        return prototypeCell
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

public extension UICollectionView {
    static let elementKindGlobalHeader = "DataSourceGlobalHeader"
    static let elementKindGlobalFooter = "DataSourceGlobalFooter"
    static let globalElementIndexPath = IndexPath(index: -1)
}

@objc public protocol FlowLayoutDelegate: UICollectionViewDelegateFlowLayout {

    /// Returns the layout strategy for the specified section.
    @objc optional func collectionView(_ collectionView: UICollectionView,
                              layout collectionViewLayout: UICollectionViewLayout,
                              layoutStrategyForSectionAt section: Int) -> FlowLayoutStrategy

    /// Returns the height for the global header. Return 0 to hide the global header
    @objc optional func heightForGlobalHeader(in collectionView: UICollectionView,
                                     layout collectionViewLayout: UICollectionViewLayout) -> CGFloat

    /// Returns the height for the global header. Return 0 to hide the global header
    @objc optional func heightForGlobalFooter(in collectionView: UICollectionView,
                                     layout collectionViewLayout: UICollectionViewLayout) -> CGFloat

}

public struct FlowLayoutSectionMetrics {

    public var headerHeight: CGFloat
    public var footerHeight: CGFloat
    public var insets: UIEdgeInsets = .zero
    public var horizontalSpacing: CGFloat = 0
    public var verticalSpacing: CGFloat = 0

    public static let zero = FlowLayoutSectionMetrics(headerHeight: 0, footerHeight: 0, insets: .zero, horizontalSpacing: 0, verticalSpacing: 0)

    public init(headerHeight: CGFloat, footerHeight: CGFloat, insets: UIEdgeInsets, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        self.headerHeight = headerHeight
        self.footerHeight = footerHeight
        self.insets = insets
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

}
