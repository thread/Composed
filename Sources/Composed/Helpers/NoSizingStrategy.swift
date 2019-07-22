import Foundation
import CoreGraphics

public struct NoSizingStrategy: CollectionUISizingStrategy {
    
    public init() { }

    public func cachedSize(forElementAt indexPath: IndexPath) -> CGSize? {
        return .zero
    }

    public func size(forElementAt indexPath: IndexPath, context: CollectionUISizingContext, dataSource: DataSource) -> CGSize {
        return .zero
    }

}
