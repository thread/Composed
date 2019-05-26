import CoreData

public typealias ManagedDataSource<Element> = BasicDataSource<ManagedDataStore<Element>> where Element: NSManagedObject

public final class ManagedDataStore<Element>: NSObject, NSFetchedResultsControllerDelegate, DataStore where Element: NSManagedObject {

    public weak var delegate: DataStoreDelegate?

    private var changeDetails: ComposedChangeDetails?

    private var fetchedResultsController: NSFetchedResultsController<Element>?
    public let managedObjectContext: NSManagedObjectContext

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

    public func indexPath(where predicate: @escaping (Element) -> Bool) -> IndexPath? {
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

        var details = ComposedChangeDetails()
        details.hasIncrementalChanges = false
        delegate?.dataStoreDidUpdate(changeDetails: details)
    }

    // MARK: NSFetchedResultsControllerDelegate

    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        changeDetails = ComposedChangeDetails()
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .delete:
            changeDetails?.removedSections.insert(sectionIndex)
        case .insert:
            changeDetails?.insertedSections.insert(sectionIndex)
        case .update:
            changeDetails?.updatedSections.insert(sectionIndex)
        default:
            changeDetails?.hasIncrementalChanges = false
        }
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            changeDetails?.removedIndexPaths.append(indexPath!)
            
            if let sections = controller.sections,
                sections.indices.contains(indexPath!.section),
                indexPath!.item == 0, sections[indexPath!.section].numberOfObjects == 1 {
                changeDetails?.hasIncrementalChanges = false
            }
        case .insert:
            changeDetails?.insertedIndexPaths.append(newIndexPath!)
            
            if let sections = controller.sections,
                newIndexPath!.section > sections.count {
                changeDetails?.hasIncrementalChanges = false
            }
        case .update:
            changeDetails?.updatedIndexPaths.append(indexPath!)
        case .move:
            if indexPath == newIndexPath {
                changeDetails?.updatedIndexPaths.append(indexPath!)
            } else {
                changeDetails?.movedIndexPaths.append((indexPath!, newIndexPath!))
            }
        @unknown default:
            changeDetails?.hasIncrementalChanges = false
        }
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let details = changeDetails ?? ComposedChangeDetails(hasIncrementalChanges: false)
        delegate?.dataStoreDidUpdate(changeDetails: details)
        changeDetails = nil
    }

}
