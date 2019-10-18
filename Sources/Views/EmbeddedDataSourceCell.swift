import UIKit

protocol EmbeddedDataSourceCellDelegate: class {
    func embeddedCell(_ cell: EmbeddedDataSourceCell, cacheValuesFor contentOffset: CGPoint, selectedIndexPaths: [IndexPath])
}

final class EmbeddedDataSourceCell: UICollectionViewCell {

    public private(set) var collectionView: UICollectionView
    internal weak var delegate: EmbeddedDataSourceCellDelegate?

    internal lazy var wrapper: DataSourceCoordinator = {
        return DataSourceCoordinator(collectionView: collectionView)
    }()
    
    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(frame: frame)
        
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addConstraints([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepare(dataSource: DataSource, contentOffset: CGPoint, selectedIndexPaths: [IndexPath]) {
        wrapper.replace(dataSource: dataSource)
        wrapper.collectionView.contentOffset = contentOffset
        selectedIndexPaths.forEach {
            wrapper.collectionView.selectItem(at: $0, animated: false, scrollPosition: [])
        }
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        delegate?.embeddedCell(self, cacheValuesFor: collectionView.contentOffset, selectedIndexPaths: wrapper.collectionView.indexPathsForSelectedItems ?? [])
        
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
