import UIKit

public final class CollectionViewSectionProviderCoordinator: NSObject, UICollectionViewDataSource, SectionProviderMapperDelegate {
    
    private let mapper: SectionProviderMapper
    private let collectionView: UICollectionView
    
    public init(collectionView: UICollectionView, sectionProvider: SectionProvider) {
        self.collectionView = collectionView
        mapper = SectionProviderMapper(globalProvider: sectionProvider)
        
        super.init()
        
        collectionView.dataSource = self
    }
    
    // MARK: - SectionProviderMapperDelegate
    
    public func sectionProviderMapper(_ sectionProviderMapper: SectionProviderMapper, didInsertSections sections: IndexSet) {
        collectionView.insertSections(sections)
    }
    
    public func sectionProviderMapper(_ sectionProviderMapper: SectionProviderMapper, didInsertElementsAt indexPaths: [IndexPath]) {
        collectionView.insertItems(at: indexPaths)
    }
    
    // MARK: - UICollectionViewDataSource
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return mapper.numberOfSections
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionUIConfigurationProvider(for: section)?.numberOfElements ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let configuration = collectionUIConfigurationProvider(for: indexPath.section) else {
            fatalError("No UI configuration available for section \(indexPath.section)")
        }
        
        let type = Swift.type(of: configuration.prototype)
        switch configuration.dequeueMethod {
        case .nib:
            let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
            collectionView.register(nib, forCellWithReuseIdentifier: configuration.reuseIdentifier)
        case .class:
            collectionView.register(type, forCellWithReuseIdentifier: configuration.reuseIdentifier)
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: configuration.reuseIdentifier, for: indexPath)
        configuration.configure(cell: cell, at: indexPath.row)
        return cell
    }
    
    private func collectionUIConfigurationProvider(for section: Int) -> CollectionUIConfiguration? {
        return (mapper.globalProvider.sections[section] as? CollectionUIConfigurationProvider)?.collectionUIConfiguration
    }
    
}
