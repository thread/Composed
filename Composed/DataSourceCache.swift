public typealias ElementSizingClosure = (ElementSizingContext) -> CGSize

public struct ElementSizingContext {
    public let prototype: UICollectionReusableView
    public let indexPath: IndexPath
    public let targetSize: CGSize
}

public enum ElementSizingStrategy {
    case hide
    case fixed(CGSize)
    case automatic(ElementSizingClosure)
}

public protocol DataSourceSizing {
    func sizingStrategy(forItemAt indexPath: IndexPath) -> ElementSizingStrategy
}

public protocol DataSourceUIProviding {
    func metrics(for section: Int) -> DataSourceSectionMetrics
    func cellConfiguration(for indexPath: IndexPath) -> CellConfiguration
    func headerConfiguration(for section: Int) -> HeaderFooterConfiguration?
    func footerConfiguration(for section: Int) -> HeaderFooterConfiguration?
}

public extension DataSourceUIProviding {
    func headerConfiguration(for section: Int) -> HeaderFooterConfiguration? { return nil }
    func footerConfiguration(for section: Int) -> HeaderFooterConfiguration? { return nil }
}

//public struct UniformSizingStrategy: ElementSizingStrategy {
//
//    private var calculatedSize: CGSize?
//
//    func cachingStrategy(forItemAt indexPath: IndexPath) -> ElementSizingStrategy {
//        if let size = calculatedSize {
//            return .useSize(size)
//        } else {
//            return .requestSizing { layout, cell, indexPath in
//                guard let layout = layout as? UICollectionViewFlowLayout else { return }
//                let targetWdith = layout.collectionView!.bounds.width
//
//                let metrics = dataSource.metrics(for: localIndexPath.section)
//                let interitemSpacing = CGFloat(metrics.columnCount - 1) * metrics.horizontalSpacing
//                let availableWidth = collectionView.bounds.width - metrics.insets.left - metrics.insets.right - interitemSpacing
//                let width = (availableWidth / CGFloat(metrics.columnCount)).rounded(.down)
//                let target = CGSize(width: width, height: 0)
//            }
//        }
//    }
//
//}
