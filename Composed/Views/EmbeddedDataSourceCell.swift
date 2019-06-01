import UIKit

protocol EmbeddedDataSourceCellDelegate: class {
    func embeddedCell(_ cell: EmbeddedDataSourceCell, cacheValuesFor contentOffset: CGPoint, selectedIndexPaths: [IndexPath])
}

final class EmbeddedDataSourceCell: UICollectionViewCell, ReusableViewNibLoadable {

    @IBOutlet public private(set) var collectionView: UICollectionView!
    internal weak var delegate: EmbeddedDataSourceCellDelegate?

    internal lazy var wrapper: DataSourceCoordinator = {
        return DataSourceCoordinator(collectionView: collectionView)
    }()

    func prepare(dataSource: DataSource, contentOffset: CGPoint, selectedIndexPaths: [IndexPath]) {
        wrapper.replace(dataSource: dataSource)
        
        wrapper.collectionView.contentOffset = contentOffset
        selectedIndexPaths.forEach {
            wrapper.collectionView.selectItem(at: $0, animated: false, scrollPosition: [])
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        delegate?.embeddedCell(self, cacheValuesFor: collectionView.contentOffset, selectedIndexPaths: collectionView.indexPathsForSelectedItems ?? [])
        
        collectionView.dataSource = nil
        collectionView.delegate = nil
        collectionView.reloadData()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .always
    }

}
