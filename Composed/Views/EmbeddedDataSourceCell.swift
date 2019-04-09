import UIKit

final class EmbeddedDataSourceCell: UICollectionViewCell, ReusableViewNibLoadable {

    private static var scrollOffsets: [IndexPath: CGPoint] = [:]

    private var indexPath: IndexPath?
    @IBOutlet public private(set) var collectionView: UICollectionView!
    @IBOutlet private weak var heightConstraint: NSLayoutConstraint!

    private lazy var wrapper: CollectionViewWrapper = {
        return CollectionViewWrapper(collectionView: collectionView)
    }()

    func prepare(dataSource: _EmbeddedDataSource) {
        wrapper.replace(dataSource: dataSource)
        wrapper.becomeActive()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 0.992)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        wrapper.resignActive()
    }

}
