import UIKit

public protocol DataSourceEditableView: UIView {
    var isEditing: Bool { get }
    func setEditing(_ editing: Bool, animated: Bool)
}

public protocol EditHandlingDataSource: DataSource {
    var isEditing: Bool { get }
    func setEditing(_ editing: Bool, animated: Bool)
    func supportsEditing(for indexPath: IndexPath) -> Bool
}

public protocol SelectionHandlingDataSource: DataSource {
    var allowsMultipleSelection: Bool { get }
    func shouldSelectElement(at indexPath: IndexPath) -> Bool
    func selectElement(at indexPath: IndexPath)
    func shouldDeselectElement(at indexPath: IndexPath) -> Bool
    func deselectElement(at indexPath: IndexPath)
}

public extension SelectionHandlingDataSource {
    func shouldSelectElement(at indexPath: IndexPath) -> Bool { return true }
    func shouldDeselectElement(at indexPath: IndexPath) -> Bool { return true }
    func deselectElement(at indexPath: IndexPath) { }
}

public enum DataSourceScrollPosition {
    case none
    case top
    case bottom
}

public protocol ScrollEventHandlingDataSource: DataSource {
    var preferredScrollPosition: DataSourceScrollPosition { get }
    func scrollToPreferredPosition() -> Bool
}

extension ScrollEventHandlingDataSource where Self: UIScrollView {

    public func scrollToPreferredPosition() -> Bool {
        let contentBounds = CGRect(origin: .zero, size: contentSize)
        let frame: CGRect

        switch preferredScrollPosition {
        case .top:
            frame = CGRect(origin: contentBounds.origin, size: CGSize(width: 1, height: 1))
        case .bottom:
            var origin = contentBounds.origin
            origin.y += contentBounds.height - 1
            frame = CGRect(origin: origin, size: CGSize(width: 1, height: 1))
        case .none:
            return false
        }

        guard !bounds.contains(frame) else { return false }
        scrollRectToVisible(frame, animated: true)
        return true
    }

}
