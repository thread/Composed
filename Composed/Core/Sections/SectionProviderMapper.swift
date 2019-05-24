import Foundation

/**
 An object that encapsulates the logic required to map `SectionProvider`s to
 a global context, allowing elements in a `Section` to be referenced via an
 `IndexPath`
 */
public final class SectionProviderMapper: SectionProviderUpdateDelegate, SectionUpdateDelegate {
    
    public weak var delegate: SectionProviderMapperDelegate?
    
    public let globalProvider: SectionProvider
    
    public var numberOfSections: Int {
        return globalProvider.numberOfSections
    }
    
    private var cachedProviderSections: [HashableProvider: Int] = [:]
    
    public init(globalProvider: SectionProvider) {
        self.globalProvider = globalProvider
        
        globalProvider.updateDelegate = self
    }
    
    public func sectionOffset(of sectionProdiver: SectionProvider) -> Int? {
        return cachedProviderSections[HashableProvider(sectionProdiver)]
    }
    
    public func sectionOffset(of section: Section) -> Int? {
        return globalProvider.sections.firstIndex(where: { $0 === section })
    }
    
    public func provider(_ provider: SectionProvider, didInsertSections sections: [Section], at indexes: IndexSet) {
        if provider is AggregateSectionProvider {
            // The inserted section couldn've been due to a new section provider
            // being inserted in to the hierachy; rebuild the offsets cache
            buildProviderSectionOffsets()
        }
        
        guard let offset = sectionOffset(of: provider) else {
            assertionFailure("Cannot call \(#function) with a provider not in the hierachy")
            return
        }
        
        let globalIndexes = IndexSet(indexes.map { $0 + offset })
        delegate?.sectionProviderMapper(self, didInsertSections: globalIndexes)
    }
    
    public func section(_ section: Section, didInsertElementAt index: Int) {
        guard let offset = sectionOffset(of: section) else {
            assertionFailure("Cannot call \(#function) with a section not in the hierachy")
            return
        }
        let indexPath = IndexPath(item: index, section: offset)
        delegate?.sectionProviderMapper(self, didInsertElementsAt: [indexPath])
    }
    
    public func section(_ section: Section, didRemoveElementAt index: Int) {
        
    }
    
    public func section(_ section: Section, didMoveElementAt index: Int, to newIndex: Int) {
        
    }
    
    private func buildProviderSectionOffsets() {
        var providerSections: [HashableProvider: Int] = [
            HashableProvider(globalProvider): 0,
        ]
        
        defer {
            cachedProviderSections = providerSections
        }
        
        guard let aggregate = globalProvider as? AggregateSectionProvider else { return }
        
        func addOffsets(forChildrenOf aggregate: AggregateSectionProvider, offset: Int = 0) {
            for child in aggregate.providers {
                let aggregateSectionOffset = aggregate.sectionOffset(for: child)
                guard aggregateSectionOffset > -1 else {
                    assertionFailure("AggregateSectionProvider shoudl return a value greater than -1 for section offset of child \(child)")
                    continue
                }
                providerSections[HashableProvider(child)] = offset + aggregateSectionOffset
                
                if let aggregate = child as? AggregateSectionProvider {
                    addOffsets(forChildrenOf: aggregate, offset: offset + aggregateSectionOffset)
                }
            }
        }
        
        addOffsets(forChildrenOf: aggregate)
    }
    
}

public protocol SectionProviderMapperDelegate: class {
    
    func sectionProviderMapper(_ sectionProviderMapper: SectionProviderMapper, didInsertSections sections: IndexSet)
    
    func sectionProviderMapper(_ sectionProviderMapper: SectionProviderMapper, didInsertElementsAt indexPaths: [IndexPath])
    
}
