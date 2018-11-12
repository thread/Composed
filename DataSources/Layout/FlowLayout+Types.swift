import UIKit

@objc public enum FlowLayoutStrategy: Int {
    // provides a column based layout
    case columns
    // provides a leading aligned layout, e.g. tags
    case alignedToLeading
}

public extension UICollectionView {
    static let elementKindGlobalHeader = "DataSourceGlobalHeader"
    static let elementKindGlobalFooter = "DataSourceGlobalFooter"
    static let globalElementIndexPath = IndexPath(index: -1)
}

@objc public protocol FlowLayoutDelegate: UICollectionViewDelegateFlowLayout {

    /// Returns the layout strategy for the specified section.
    @objc func collectionView(_ collectionView: UICollectionView,
                              layout collectionViewLayout: UICollectionViewLayout,
                              layoutStrategyForSectionAt section: Int) -> FlowLayoutStrategy

    /// Returns the height for the global header. Return 0 to hide the global header
    @objc func heightForGlobalHeader(in collectionView: UICollectionView,
                                     layout collectionViewLayout: UICollectionViewLayout) -> CGFloat

    /// Returns the height for the global header. Return 0 to hide the global header
    @objc func heightForGlobalFooter(in collectionView: UICollectionView,
                                     layout collectionViewLayout: UICollectionViewLayout) -> CGFloat

}

public struct FlowLayoutSectionMetrics {

    public var headerHeight: CGFloat = 0
    public var footerHeight: CGFloat = 0

    public var insets: UIEdgeInsets = .zero
    public var itemSpacing: CGFloat = 0
    public var lineSpacing: CGFloat = 0

    public init() { }
    public static let zero = FlowLayoutSectionMetrics()

}
