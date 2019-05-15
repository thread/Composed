import UIKit

final class EmbeddedDataSourceCell: UICollectionViewCell, ReusableViewNibLoadable {

    @IBOutlet public private(set) var collectionView: UICollectionView!

    private lazy var wrapper: DataSourceCoordinator = {
        return DataSourceCoordinator(collectionView: collectionView)
    }()

    func prepare(dataSource: _EmbeddedDataSource) {
        wrapper.replace(dataSource: dataSource)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .always
    }

}
