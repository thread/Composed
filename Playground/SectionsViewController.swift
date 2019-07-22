import UIKit
import Composed

final class SectionsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  
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
        sectionProvider.append(personSection)

        collectionView.alwaysBounceVertical = true

        let layout = FlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        collectionView.collectionViewLayout = layout

        coordinator = CollectionViewSectionProviderCoordinator(collectionView: collectionView, sectionProvider: sectionProvider)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            personSection.append(element: Person(name: "Shaps", age: 39))
        }
    }

    let cell = PersonCell.fromNib
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let target = CGSize(width: collectionView.bounds.width - 40, height: 0)
        return cell.contentView.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
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
