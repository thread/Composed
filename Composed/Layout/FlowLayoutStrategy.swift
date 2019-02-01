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
