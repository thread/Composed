public protocol DataSourceUIEditingCell {
    var isEditing: Bool { get }
    func setEditing(_ editing: Bool, animated: Bool)
}

public protocol DataSourceUIEditing {
    var isEditing: Bool { get }
    func setEditing(_ editing: Bool, animated: Bool)
    func supportsEditing(for indexPath: IndexPath) -> Bool
}

public protocol DataSourceUISelecting {
    func supportsSelection(for indexPath: IndexPath) -> Bool
    func selectElement(for indexPath: IndexPath)
    func deselectElement(for indexPath: IndexPath)
}

public extension DataSourceUISelecting {
    func supportsSelection(for indexPath: IndexPath) -> Bool { return true }
    func deselectElement(for indexPath: IndexPath) { }
}

public struct DataSourceUISectionMetrics {

    public let insets: UIEdgeInsets
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat

    public init(insets: UIEdgeInsets, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        self.insets = insets
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

}
