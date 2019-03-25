import CoreData

public typealias ManagedDataSource<Element> = BasicDataSource<ManagedDataStore<Element>> where Element: NSManagedObject

public final class ManagedDataStore<Element>: NSObject, NSFetchedResultsControllerDelegate, DataStore where Element: NSManagedObject {

    public weak var delegate: DataStoreDelegate?
    private var updates: (() -> Void)?
    private var operations: [DataSourceUpdate] = []
    private var forceReload: Bool = false

    private var fetchedResultsController: NSFetchedResultsController<Element>?
    private let managedObjectContext: NSManagedObjectContext

    public private(set) var request: NSFetchRequest<Element>?
    public private(set) var sectionNameKeyPath: String?

    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    public var numberOfSections: Int {
        return fetchedResultsController?.sections?.count ?? 0
    }

    public func numberOfElements(in section: Int) -> Int {
        return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }

    public func indexPath(of element: Element) -> IndexPath? {
        return fetchedResultsController?.indexPath(forObject: element)
    }

    public func element(at indexPath: IndexPath) -> Element {
        return fetchedResultsController!.object(at: indexPath)
    }

    public func indexPath(where predicate: @escaping (Any) -> Bool) -> IndexPath? {
        for section in 0..<numberOfSections {
            for item in 0..<numberOfElements(in: section) {
                let indexPath = IndexPath(item: item, section: section)
                let element = self.element(at: indexPath)
                if predicate(element) { return indexPath }
            }
        }

        return nil
    }

    public func prepare(request: NSFetchRequest<Element>, sectionNameKeyPath: String? = nil) {
        self.sectionNameKeyPath = sectionNameKeyPath
        self.request = request

        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
        fetchedResultsController?.delegate = self
    }

    public func reload() {
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            fatalError(error.localizedDescription)
        }

        delegate?.dataStore(willPerform: [])
        delegate?.dataStoreDidReload()
        delegate?.dataStore(didPerform: [])
    }

    // MARK: -

    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updates = nil
        operations.removeAll()
        forceReload = false
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let pendingUpdates = updates

        switch type {
        case .delete:
            operations.append(.deleteSections([sectionIndex]))
        case .insert:
            operations.append(.insertSections([sectionIndex]))
        default:
            operations.append(.updateSections([sectionIndex]))
        }

        updates = { [delegate] in
            guard Thread.isMainThread else { fatalError() }
            pendingUpdates?()

            switch type {
            case .delete:
                delegate?.dataStore(didDeleteSections: IndexSet(integer: sectionIndex))
            case .insert:
                delegate?.dataStore(didInsertSections: IndexSet(integer: sectionIndex))
            default:
                delegate?.dataStore(didUpdateSections: IndexSet(integer: sectionIndex))
            }
        }
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let pendingUpdates = updates

        switch type {
        case .delete:
            operations.append(.deleteIndexPaths([indexPath!]))
        case .insert:
            operations.append(.insertIndexPaths([newIndexPath!]))
        case .update:
            operations.append(.updateIndexPaths([indexPath!]))
        case .move:
            operations.append(.moveIndexPaths([(source: indexPath!, target: newIndexPath!)]))
        @unknown default:
            break
        }

        updates = { [delegate] in
            guard Thread.isMainThread else { fatalError() }
            pendingUpdates?()

            switch type {
            case .delete:
                if self.numberOfElements(in: indexPath!.section) == 1 {
                    self.forceReload = true
                } else {
                    delegate?.dataStore(didDeleteIndexPaths: [indexPath!])
                }
            case .insert:
                if self.numberOfElements(in: newIndexPath!.section) == 0 {
                    self.forceReload = true
                } else {
                    delegate?.dataStore(didInsertIndexPaths: [newIndexPath!])
                }
            case .update:
                delegate?.dataStore(didUpdateIndexPaths: [indexPath!])
            case .move:
                delegate?.dataStore(didMoveFromIndexPath: indexPath!, toIndexPath: newIndexPath!)
            @unknown default:
                break
            }
        }
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if forceReload {
            delegate?.dataStoreDidReload()
            forceReload = false
            return
        }

        defer {
            delegate?.dataStore(willPerform: operations)
        }

        delegate?.dataStore(performBatchUpdates: {
            updates?()
        }, completion: { [unowned self] _ in
            self.delegate?.dataStore(didPerform: self.operations)
        })
    }

}
