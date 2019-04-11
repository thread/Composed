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
            guard let changeDetails = changeInstance.changeDetails(for: result) else { return }

            guard changeDetails.hasIncrementalChanges else {
                delegate?.dataStoreDidReload()
                return
            }

            let changeset = PhotosChangeset(changeDetails: changeDetails)

            let updates = changeset.updates

            delegate?.dataStore(performBatchUpdates: {
                result = changeDetails.fetchResultAfterChanges
                delegate?.dataStore(willPerform: updates)

                if !changeset.deletedSections.isEmpty {
                    delegate?.dataStore(didDeleteSections: IndexSet(changeset.deletedSections))
                }

                if !changeset.insertedSections.isEmpty {
                    delegate?.dataStore(didInsertSections: IndexSet(changeset.insertedSections))
                }

                if !changeset.updatedSections.isEmpty {
                    delegate?.dataStore(didUpdateSections: IndexSet(changeset.updatedSections))
                }

                for (source, target) in changeset.movedSections {
                    delegate?.dataStore(didMoveSection: source, to: target)
                }

                if !changeset.deletedIndexPaths.isEmpty {
                    delegate?.dataStore(didDeleteIndexPaths: changeset.deletedIndexPaths)
                }

                if !changeset.insertedIndexPaths.isEmpty {
                    delegate?.dataStore(didInsertIndexPaths: changeset.insertedIndexPaths)
                }

                if !changeset.updatedIndexPaths.isEmpty {
                    delegate?.dataStore(didUpdateIndexPaths: changeset.updatedIndexPaths)
                }

                for (source, target) in changeset.movedIndexPaths {
                    delegate?.dataStore(didMoveFromIndexPath: source, toIndexPath: target)
                }
            }, completion: { [weak delegate] _ in
                delegate?.dataStore(didPerform: updates)
            })
        }
    }

}

private struct PhotosChangeset<Asset>: DataSourceChangeset where Asset: PHObject {

    private let changeDetails: PHFetchResultChangeDetails<Asset>

    init(changeDetails: PHFetchResultChangeDetails<Asset>) {
        self.changeDetails = changeDetails
    }

    var deletedSections: [Int] { return [] }
    var insertedSections: [Int] { return [] }
    var updatedSections: [Int] { return [] }
    var movedSections: [(source: Int, target: Int)] { return [] }

    var deletedIndexPaths: [IndexPath] {
        return changeDetails.removedIndexes?
            .compactMap { IndexPath(item: $0, section: 0) }
            ?? []
    }

    var insertedIndexPaths: [IndexPath] {
        return changeDetails.insertedIndexes?
            .compactMap { IndexPath(item: $0, section: 0) }
            ?? []
    }

    var updatedIndexPaths: [IndexPath] {
        return changeDetails.changedIndexes?
            .compactMap { IndexPath(item: $0, section: 0) }
            ?? []
    }

    var movedIndexPaths: [(source: IndexPath, target: IndexPath)] {
        var moves: [(IndexPath, IndexPath)] = []

        changeDetails.enumerateMoves { from, to in
            moves.append((IndexPath(item: from, section: 0), IndexPath(item: to, section: 0)))
        }

        return moves
    }

}
