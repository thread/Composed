import UIKit

public protocol EditHandling {
    var isEditing: Bool { get }
    func setEditing(_ editing: Bool, animated: Bool)
}

public protocol EditHandlingDataSource: DataSource, EditHandling {
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
