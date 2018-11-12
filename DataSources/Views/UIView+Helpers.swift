import UIKit

public extension UIView {

    @discardableResult
    func sendAction(_ action: Selector) -> Bool {
        let sender = self
        var target: UIResponder? = sender

        while target != nil && target?.canPerformAction(action, withSender: sender) == false {
            target = target?.next
        }

        guard let t = target else { return false }
        return UIApplication.shared.sendAction(action, to: t, from: sender, for: nil)
    }

}
