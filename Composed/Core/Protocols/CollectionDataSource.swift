import Foundation

public protocol CollectionDataSource: DataSource, DataStoreDelegate {
    associatedtype Store: DataStore
    func element(at indexPath: IndexPath) -> Store.Element
}

public extension CollectionDataSource {

    subscript(indexPath: IndexPath) -> Store.Element {
        return element(at: indexPath)
    }

    func dataStoreDidUpdate(changeDetails: ComposedChangeDetails) {
        updateDelegate?.dataSource(self, performUpdates: changeDetails)
    }

}

extension CollectionDataSource where Store.Element: Equatable {

    func indexPath(of element: Store.Element) -> IndexPath? {
        return indexPath { other in
            guard let other = other as? Store.Element else { return false }
            return other == element
        }
    }
}
