import CoreData

public final class ManagedDataStore<Element>: NSObject, NSFetchedResultsControllerDelegate, DataStore where Element: NSManagedObject {

    public weak var delegate: DataStoreDelegate?
    private var updates: (() -> Void)?
    private var operations: [DataSourceUpdate] = []

    private var fetchedResultsController: NSFetchedResultsController<Element>?
    private let managedObjectContext: NSManagedObjectContext

    public var request: NSFetchRequest<Element>? {
        didSet { invalidate() }
    }

    public var sectionNameKeyPath: String? {
        didSet { invalidate() }
    }

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

    public func invalidate() {
        guard let request = request else { return }
        request.returnsObjectsAsFaults = false

        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
        fetchedResultsController?.delegate = self

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
        }

        updates = { [delegate] in
            guard Thread.isMainThread else { fatalError() }
            pendingUpdates?()

            switch type {
            case .delete:
                delegate?.dataStore(didDeleteIndexPaths: [indexPath!])
            case .insert:
                delegate?.dataStore(didInsertIndexPaths: [newIndexPath!])
            case .update:
                delegate?.dataStore(didUpdateIndexPaths: [indexPath!])
            case .move:
                delegate?.dataStore(didMoveFromIndexPath: indexPath!, toIndexPath: newIndexPath!)
            }
        }
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        defer {
            // need to keep this after the call to performBatchUpdates to at least ensure the models are up to date
            delegate?.dataStore(willPerform: operations)
        }

        delegate?.dataStore(performBatchUpdates: {
            updates?()
        }, completion: { [unowned self] _ in
            self.delegate?.dataStore(didPerform: self.operations)
        })
    }

}
