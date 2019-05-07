import Foundation

public struct NoSizingStrategy: CollectionUISizingStrategy {

    public func cachedSize(forElementAt indexPath: IndexPath) -> CGSize? {
        return nil
    }

    public func size(forElementAt indexPath: IndexPath, context: CollectionUISizingContext, dataSource: DataSource) -> CGSize {
        return .zero
    }

}

public extension CollectionUIProvidingDataSource where Self: EmptyDataSource {

    func sizingStrategy(in collectionView: UICollectionView) -> CollectionUISizingStrategy {
        return NoSizingStrategy()
    }

    func cellConfiguration(for indexPath: IndexPath) -> CollectionUIViewProvider {
        fatalError("This should never be called since an EmptyDataSource will return 0 elements")
    }

}
