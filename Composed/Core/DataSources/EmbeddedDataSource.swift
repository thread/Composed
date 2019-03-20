import UIKit

public final class EmbeddedContentDataSource<Element>: SectionedDataSource<Element>, CollectionUIProvidingDataSource where Element: CollectionViewDataSource {

    public let metrics: CollectionUISectionMetrics
    private let dataSources: [Element]

    public init(dataSources: [Element], metrics: CollectionUISectionMetrics) {
        self.dataSources = dataSources
        self.metrics = metrics
        super.init(elements: dataSources)
    }

    public func metrics(for section: Int) -> CollectionUISectionMetrics {
        return metrics
    }

    public func sizingStrategy() -> CollectionUISizingStrategy {
        return ColumnSizingStrategy(columnCount: 1, sizingMode: .automatic(isUniform: true))
    }

    public func cellConfiguration(for indexPath: IndexPath) -> DataSourceUIConfiguration {
        return DataSourceUIConfiguration(prototype: EmbeddedDataSourceCell(), dequeueSource: .class) { [unowned self] cell, _, _ in
            cell.prepare(dataSource: EmbeddedContentDataSource(dataSources: self.dataSources, metrics: self.metrics))
        }
    }

}
