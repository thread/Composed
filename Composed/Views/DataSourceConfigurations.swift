import UIKit

public struct CellConfiguration {

    public enum Source {
        case nib
        case `class`
    }

    public typealias Configuration = (DataSourceCell, IndexPath) -> Void

    public let dequeueSource: Source
    public let prototype: DataSourceCell
    public let configure: Configuration

    public init(prototype: DataSourceCell, dequeueSource: Source, _ configure: @escaping Configuration) {
        self.prototype = prototype
        self.dequeueSource = dequeueSource
        self.configure = configure
    }

}

public struct HeaderFooterConfiguration {

    public enum Source {
        case nib
        case `class`
    }

    public typealias Configuration = (UICollectionReusableView, Int) -> Void

    public let dequeueSource: Source
    public let prototype: UICollectionReusableView
    public let configure: Configuration

    public init(prototype: UICollectionReusableView, dequeueSource: Source, _ configure: @escaping Configuration) {
        self.prototype = prototype
        self.dequeueSource = dequeueSource
        self.configure = configure
    }

}
