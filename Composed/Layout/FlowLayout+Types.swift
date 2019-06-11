import UIKit

public extension UICollectionView {
    static let elementKindBackground = "DataSourceBackgroundView"
    static let elementKindGlobalHeader = "DataSourceGlobalHeader"
    static let elementKindGlobalFooter = "DataSourceGlobalFooter"
    static let globalElementIndexPath = IndexPath(item: 0, section: 0)
    
    static let backgroundZIndex: Int = -100
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
