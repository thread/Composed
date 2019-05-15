import Photos

public typealias PhotosDataSource<Asset: PHObject> = BasicDataSource<PhotosDataStore<Asset>>

public final class PhotosDataStore<Element>: NSObject, PHPhotoLibraryChangeObserver, DataStore where Element: PHObject {

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    public weak var dataSource: DataSource?
    public weak var delegate: DataStoreDelegate?
    public private(set) var result: PHFetchResult<Element>

    public init(result: PHFetchResult<Element>) {
        self.result = result
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    public var numberOfSections: Int {
        return 1
    }

    public func numberOfElements(in section: Int) -> Int {
        return result.count
    }

    public func element(at indexPath: IndexPath) -> Element {
        guard indexPath.section == 0 else {
            fatalError("Invalid section index: \(indexPath.section). Should always be 0")
        }

        return result.object(at: indexPath.item)
    }

    public func indexPath(of element: Element) -> IndexPath {
        return IndexPath(item: result.index(of: element), section: 0)
    }

    public func indexPath(where predicate: @escaping (Element) -> Bool) -> IndexPath? {
        fatalError("Unsupported")
    }

    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.sync {
            guard let details = changeInstance.changeDetails(for: result) else { return }
            var composedDetails = ComposedChangeDetails(hasIncrementalChanges: details.hasIncrementalChanges)

            composedDetails.removedIndexPaths = details.removedIndexes?
                .compactMap { IndexPath(item: $0, section: 0) } ?? []
            composedDetails.insertedIndexPaths = details.insertedIndexes?
                .compactMap { IndexPath(item: $0, section: 0) } ?? []
            composedDetails.updatedIndexPaths = details.changedIndexes?
                .compactMap { IndexPath(item: $0, section: 0) } ?? []

            var moves: [(IndexPath, IndexPath)] = []
            details.enumerateMoves { source, target in
                moves.append((IndexPath(item: source, section: 0), IndexPath(item: target, section: 0)))
            }

            composedDetails.movedIndexPaths = moves

            delegate?.dataStoreDidUpdate(changeDetails: composedDetails)
        }
    }

}
