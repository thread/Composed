import UIKit

final class EmbeddedDataSourceCell: UICollectionViewCell {

    private static var scrollOffsets: [IndexPath: CGPoint] = [:]

    private var indexPath: IndexPath?

    private lazy var wrapper: CollectionViewWrapper = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        let wrapper = CollectionViewWrapper(collectionView: collectionView)

        contentView.backgroundColor = .clear
        contentView.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
            ])

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            ])

        return wrapper
    }()

    func prepare(dataSource: CollectionViewDataSource) {
        wrapper.replace(dataSource: dataSource)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let offset = type(of: self).scrollOffsets[layoutAttributes.indexPath] else { return }

        wrapper.collectionView.setContentOffset(offset, animated: false)
        indexPath = layoutAttributes.indexPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        guard let indexPath = indexPath else { return }

        _ = type(of: self).scrollOffsets[indexPath]
        type(of: self).scrollOffsets[indexPath] = wrapper.collectionView.contentOffset
    }

}
