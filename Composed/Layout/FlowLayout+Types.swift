import UIKit

public extension UICollectionView {
    static let elementKindGlobalHeader = "DataSourceGlobalHeader"
    static let elementKindGlobalFooter = "DataSourceGlobalFooter"
    static let globalElementIndexPath = IndexPath(item: 0, section: -1)

    static let globalHeaderZIndex: Int = 400
    static let globalFooterZIndex: Int = 300
    static let sectionHeaderZIndex: Int = 200
    static let sectionFooterZIndex: Int = 100
}

@objc public protocol FlowLayoutDelegate: UICollectionViewDelegateFlowLayout {

    /// Returns the height for the global header. Return 0 to hide the global header
    @objc optional func heightForGlobalHeader(in collectionView: UICollectionView,
                                     layout collectionViewLayout: UICollectionViewLayout) -> CGFloat

    /// Returns the height for the global header. Return 0 to hide the global header
    @objc optional func heightForGlobalFooter(in collectionView: UICollectionView,
                                     layout collectionViewLayout: UICollectionViewLayout) -> CGFloat

    /// Returns the class to use for providing a 'grouped' backgroundView behind the items for the specified section
    @objc optional func backgroundViewClass(in collectionView: UICollectionView,
                                            forSectionAt section: Int) -> UICollectionReusableView.Type?

}

internal struct FlowLayoutSectionMetrics {

    internal var headerHeight: CGFloat
    internal var footerHeight: CGFloat
    internal var insets: UIEdgeInsets = .zero
    internal var horizontalSpacing: CGFloat = 0
    internal var verticalSpacing: CGFloat = 0

    internal static let zero = FlowLayoutSectionMetrics(headerHeight: 0, footerHeight: 0, insets: .zero, horizontalSpacing: 0, verticalSpacing: 0)

    internal init(headerHeight: CGFloat, footerHeight: CGFloat, insets: UIEdgeInsets, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        self.headerHeight = headerHeight
        self.footerHeight = footerHeight
        self.insets = insets
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

}
