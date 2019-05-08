import UIKit

public extension UICollectionViewFlowLayout {

    func columnWidth(forColumnCount columnCount: Int, inSection section: Int) -> CGFloat {
        guard let collectionView = collectionView else { return 0 }

        let metrics = self.metrics(forSection: section)
        let interitemSpacing = CGFloat(columnCount - 1) * metrics.horizontalSpacing
        let availableWiwdth = collectionView.bounds.width - metrics.insets.left - metrics.insets.right - interitemSpacing

        return (availableWiwdth / CGFloat(columnCount)).rounded(.down)
    }

    internal func metrics(forSection section: Int) -> FlowLayoutSectionMetrics {
        guard let collectionView = collectionView,
            let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else {
                return .zero
        }

        let headerHeight = delegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section).height
            ?? headerReferenceSize.height

        let footerHeight = delegate.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section).height
            ?? footerReferenceSize.height

        let insets = delegate.collectionView?(collectionView, layout: self, insetForSectionAt: section)
            ?? sectionInset

        let itemSpacing = delegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section)
            ?? minimumInteritemSpacing

        let lineSpacing = delegate.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAt: section)
            ?? minimumLineSpacing

        return FlowLayoutSectionMetrics(headerHeight: headerHeight,
                                        footerHeight: footerHeight,
                                        insets: insets,
                                        horizontalSpacing: itemSpacing,
                                        verticalSpacing: lineSpacing)
    }

}
