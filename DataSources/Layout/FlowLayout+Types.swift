import UIKit

@objc public protocol FlowLayoutStrategy: NSObjectProtocol {
    var headerStrategy: HeaderLayoutStrategy? { get }

    func insets(in section: Int) -> UIEdgeInsets
    func horizontalSpacing(in section: Int) -> CGFloat
    func verticalSpacing(in section: Int) -> CGFloat
    func cellSize(for indexPath: IndexPath, in layout: UICollectionViewFlowLayout) -> CGSize
}

internal final class FlowLayoutNoStrategy: NSObject, FlowLayoutStrategy {
    var layout: UICollectionViewLayout?
    var headerStrategy: HeaderLayoutStrategy?

    func insets(in section: Int) -> UIEdgeInsets { return .zero }
    func horizontalSpacing(in section: Int) -> CGFloat { return 0 }
    func verticalSpacing(in section: Int) -> CGFloat { return 0 }
    func cellSize(for indexPath: IndexPath, in layout: UICollectionViewFlowLayout) -> CGSize { return .zero }
}

open class HeaderLayoutStrategy: NSObject {

    private let prototypeHeader: UICollectionReusableView

    public init(prototypeHeader: DataSourceHeaderView) {
        self.prototypeHeader = prototypeHeader
    }

    public func headerSize(in section: Int, in layout: UICollectionViewLayout) -> CGSize {
        let width = layout.collectionView?.bounds.width ?? 0
        let target = CGSize(width: width, height: 0)
        return prototypeHeader.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
    }

}

open class FlowLayoutColumnsStrategy<CellType>: NSObject, FlowLayoutStrategy where CellType: DataSourceCell & ReusableViewNibLoadable {

    public var layout: UICollectionViewLayout?
    public let columns: Int
    public let metrics: FlowLayoutSectionMetrics

    public let headerStrategy: HeaderLayoutStrategy?
    private let prototypeCell: CellType

    public init(columns: Int = 1, metrics: FlowLayoutSectionMetrics, headerStrategy: HeaderLayoutStrategy? = nil) {
        self.headerStrategy = headerStrategy
        self.prototypeCell = CellType.fromNib
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

    public func cellSize(for indexPath: IndexPath, in layout: UICollectionViewFlowLayout) -> CGSize {
        guard let delegate = layout.collectionView?.delegate as? UICollectionViewDelegateFlowLayout else { return .zero }
        let width = layout.columnWidth(forColumnCount: columns, inSection: indexPath.section, delegate: delegate)
        let target = CGSize(width: width, height: 0)
        return prototypeCell.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
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
