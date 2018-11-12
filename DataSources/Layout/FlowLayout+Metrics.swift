import UIKit

public extension UICollectionViewFlowLayout {

    func columnWidth<LayoutDelegate: UICollectionViewDelegateFlowLayout>(forColumnCount columnCount: Int, inSection section: Int, layoutDelegate: LayoutDelegate) -> CGFloat {
        guard let collectionView = collectionView else { return 0 }

        let metrics = self.metrics(forSection: section, layoutDelegate: layoutDelegate)
        let interitemSpacing = CGFloat(columnCount - 1) * metrics.itemSpacing
        let availableWiwdth = collectionView.bounds.width - metrics.insets.left - metrics.insets.right - interitemSpacing

        return (availableWiwdth / CGFloat(columnCount)).rounded(.down)
    }

    func boundaryMetrics(for attributes: UICollectionViewLayoutAttributes) -> (minY: CGFloat, maxY: CGFloat) {
        guard let collectionView = collectionView  else { return (0, 0) }
        guard let layoutDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else { return (0, 0) }

        let section = attributes.indexPath.count > 1
            ? attributes.indexPath.section
            : 0

        // Prevents a divide by zero exception
        let lastItem = collectionView.numberOfItems(inSection: section) - 1
        if lastItem < 0 { return (0, 0) }

        guard let firstAttributes = layoutAttributesForItem(at: IndexPath(item: 0, section: section)),
            let lastAttributes = layoutAttributesForItem(at: IndexPath(item: lastItem, section: section)) else {
                return (0, 0)
        }

        let frame = attributes.frame

        // Section Boundaries:
        let metrics = self.metrics(forSection: section, layoutDelegate: layoutDelegate)
        //   The section should not be higher than the top of its first cell
        let minY = firstAttributes.frame.minY - frame.height - metrics.insets.top
        //   The section should not be lower than the bottom of its last cell
        let maxY = lastAttributes.frame.maxY - frame.height + metrics.insets.bottom

        return (minY, maxY)
    }

    func metrics(forSection section: Int, layoutDelegate: UICollectionViewDelegateFlowLayout) -> FlowLayoutSectionMetrics {
        guard let collectionView = collectionView else { return .zero }

        let headerHeight = layoutDelegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section).height
            ?? headerReferenceSize.height

        let footerHeight = layoutDelegate.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section).height
            ?? footerReferenceSize.height

        let insets = layoutDelegate.collectionView?(collectionView, layout: self, insetForSectionAt: section)
            ?? sectionInset

        let itemSpacing = layoutDelegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section)
            ?? minimumInteritemSpacing

        let lineSpacing = layoutDelegate.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAt: section)
            ?? minimumLineSpacing

        var metrics = FlowLayoutSectionMetrics()
        metrics.headerHeight = headerHeight
        metrics.footerHeight = footerHeight
        metrics.insets = insets
        metrics.itemSpacing = itemSpacing
        metrics.lineSpacing = lineSpacing

        return metrics
    }

    func firstSectionMetrics() -> FlowLayoutSectionMetrics {
        guard let layoutDelegate = collectionView?.delegate as? UICollectionViewDelegateFlowLayout else { return .zero }
        return metrics(forSection: 0, layoutDelegate: layoutDelegate)
    }

}
