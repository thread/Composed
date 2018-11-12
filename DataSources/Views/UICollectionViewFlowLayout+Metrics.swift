import UIKit

// MOVED > FlowLayout+Metrics.swift

//public extension DataSourceLayout {
//
//    func columnWidth<LayoutDelegate: UICollectionViewDelegateFlowLayout>(forColumnCount columnCount: Int, inSection section: Int, layoutDelegate: LayoutDelegate) -> CGFloat {
//        let metrics = self.metrics(forSection: section, layoutDelegate: layoutDelegate)
//        return columnWidth(forColumnCount: columnCount, itemSpacing: metrics.itemSpacing, insets: metrics.insets)
//    }
//
//    func columnWidth(forColumnCount columnCount: Int, itemSpacing: CGFloat, insets: UIEdgeInsets) -> CGFloat {
//        guard let collectionView = collectionView else { return 0 }
//
//        let interitemSpacing = CGFloat(columnCount - 1) * itemSpacing
//        let availableWiwdth = collectionView.bounds.width - insets.left - insets.right - interitemSpacing
//
//        return (availableWiwdth / CGFloat(columnCount)).rounded(.down)
//    }
//
//    func boundaryMetrics(for attributes: UICollectionViewLayoutAttributes) -> (minY: CGFloat, maxY: CGFloat) {
//        guard let collectionView = collectionView  else { return (0, 0) }
//        guard let layoutDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else { return (0, 0) }
//
//        let section = attributes.indexPath.section
//
//        // Prevents a divide by zero exception
//        let lastItem = collectionView.numberOfItems(inSection: section) - 1
//        if lastItem < 0 { return (0, 0) }
//
//        guard let firstAttributes = layoutAttributesForItem(at: IndexPath(item: 0, section: section)),
//            let lastAttributes = layoutAttributesForItem(at: IndexPath(item: lastItem, section: section)) else {
//                return (0, 0)
//        }
//
//        let frame = attributes.frame
//
//        // Section Boundaries:
//        let metrics = self.metrics(forSection: section, layoutDelegate: layoutDelegate)
//        //   The section should not be higher than the top of its first cell
//        let minY = firstAttributes.frame.minY - frame.height - metrics.insets.top
//        //   The section should not be lower than the bottom of its last cell
//        let maxY = lastAttributes.frame.maxY - frame.height + metrics.insets.bottom
//
//        return (minY, maxY)
//    }
//
//    func metrics(forSection section: Int, layoutDelegate: UICollectionViewDelegateFlowLayout) -> Metrics {
//        guard let collectionView = collectionView else { return .zero }
//
//        let headerHeight = layoutDelegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section).height
//            ?? headerReferenceSize.height
//
//        let footerHeight = layoutDelegate.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section).height
//            ?? footerReferenceSize.height
//
//        let insets = layoutDelegate.collectionView?(collectionView, layout: self, insetForSectionAt: section)
//            ?? sectionInset
//
//        let itemSpacing = layoutDelegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section)
//            ?? minimumInteritemSpacing
//
//        let lineSpacing = layoutDelegate.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAt: section)
//            ?? minimumLineSpacing
//
//        return Metrics(headerHeight: headerHeight, footerHeight: footerHeight, insets: insets, itemSpacing: itemSpacing, lineSpacing: lineSpacing)
//    }
//
//    func firstSectionMetrics() -> Metrics {
//        guard let layoutDelegate = collectionView?.delegate as? UICollectionViewDelegateFlowLayout else { return .zero }
//        return metrics(forSection: 0, layoutDelegate: layoutDelegate)
//    }
//
//}
