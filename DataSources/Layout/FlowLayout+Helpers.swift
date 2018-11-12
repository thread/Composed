import UIKit

internal extension FlowLayout {

    func layoutStrategy(inSection section: Int) -> FlowLayoutStrategy {
        guard let collectionView = collectionView else { return .columns }

        return (collectionView.delegate as? FlowLayoutDelegate)?
            .collectionView(collectionView, layout: self, layoutStrategyForSectionAt: section)
            ?? .columns
    }

    var sizeForGlobalHeader: CGSize {
        guard let collectionView = collectionView else { return .zero }
        let height = (collectionView.delegate as? FlowLayoutDelegate)?
            .heightForGlobalHeader(in: collectionView, layout: self) ?? 0
        return CGSize(width: collectionView.bounds.width, height: height)
    }

    var sizeForGlobalFooter: CGSize {
        guard let collectionView = collectionView else { return .zero }
        let height = (collectionView.delegate as? FlowLayoutDelegate)?
            .heightForGlobalFooter(in: collectionView, layout: self) ?? 0
        return CGSize(width: collectionView.bounds.width, height: height)
    }

}

internal extension FlowLayout {

    var requiresLayout: Bool {
        guard let collectionView = collectionView else { return false }

        for section in 0..<collectionView.numberOfSections {
            if layoutStrategy(inSection: section) == .alignedToLeading {
                return true
            }
        }

        return sizeForGlobalHeader.height != 0 || sizeForGlobalFooter.height != 0
    }

}
