import UIKit

internal extension FlowLayout {

    var sizeForGlobalHeader: CGSize {
        guard let collectionView = collectionView else { return .zero }
        let height = (collectionView.delegate as? FlowLayoutDelegate)?
            .heightForGlobalHeader?(in: collectionView, layout: self) ?? 0
        return height == 0 ? .zero : CGSize(width: collectionView.bounds.width, height: height)
    }

    var sizeForGlobalFooter: CGSize {
        guard let collectionView = collectionView else { return .zero }
        let height = (collectionView.delegate as? FlowLayoutDelegate)?
            .heightForGlobalFooter?(in: collectionView, layout: self) ?? 0
        return height == 0 ? .zero : CGSize(width: collectionView.bounds.width, height: height)
    }

}
