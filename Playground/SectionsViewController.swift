import UIKit
import Composed

final class SectionsViewController: UICollectionViewController {
  
    private var coordinator: CollectionViewSectionProviderCoordinator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let personSection = PersonSection(elements: [
            Person(name: "Joseph Duffy", age: 25),
            Person(name: "Joseph Duffy", age: 26),
            Person(name: "Joseph Duffy", age: 27),
            Person(name: "Joseph Duffy", age: 28),
            Person(name: "Joseph Duffy", age: 29),
            Person(name: "Joseph Duffy", age: 30),
        ])
        let sectionProvider = ComposedSectionProvider()
        sectionProvider.append(personSection)
        coordinator = CollectionViewSectionProviderCoordinator(collectionView: collectionView, sectionProvider: sectionProvider)
    }
    
}

final class PersonSection: ArraySection<Person>, CollectionUIConfigurationProvider {
    
    private(set) lazy var collectionUIConfiguration: CollectionUIConfiguration = {
        return SectionCollectionUIConfiguration(section: self, prototype: PersonCell.fromNib, cellDequeueMethod: .nib, cellConfigurator: { cell, index, section in
            let person = section.element(at: index)
            cell.prepare(person: person)
        })
    }()
    
}
