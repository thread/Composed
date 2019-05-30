import UIKit
import Composed

struct Person {
    var name: String
    var age: Int
}

final class Family: PeopleArrayDataSource { }
final class Friends: PeopleArrayDataSource { }
final class Coworkers: PeopleArrayDataSource { }
final class Websites: PeopleArrayDataSource { }
final class FamilyAndFriends: PeopleSectionedDataSource { }
final class Countries: PeopleSectionedDataSource { }

class PeopleArrayDataSource: ArrayDataSource<Person>, CollectionUIProvidingDataSource {

    var title: String?
    
    init(elements: [Person], title: String? = nil) {
        super.init(store: ArrayDataStore(elements: elements))
        self.title = title
    }

    func sizingStrategy(for traitCollection: UITraitCollection, layoutSize: CGSize) -> CollectionUISizingStrategy {
        return ColumnSizingStrategy(columnCount: 1, sizingMode: .automatic(isUniform: false))
    }

    func metrics(for section: Int, traitCollection: UITraitCollection, layoutSize: CGSize) -> CollectionUISectionMetrics {
        return CollectionUISectionMetrics(insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), horizontalSpacing: 8, verticalSpacing: 8)
    }

    func cellConfiguration(for indexPath: IndexPath) -> CollectionUIViewProvider {
        return CollectionUIViewProvider(prototype: PersonCell.fromNib, dequeueMethod: .nib) { cell, indexPath, _ in
            cell.prepare(person: self.element(at: indexPath))
        }
    }

    func headerConfiguration(for section: Int) -> CollectionUIViewProvider? {
        return title.map { title in
            CollectionUIViewProvider(prototype: HeaderView.fromNib, dequeueMethod: .nib) { view, indexPath, _ in
                view.prepare(title: title)
            }
        }
    }

    func backgroundViewClass(for section: Int) -> UICollectionReusableView.Type? {
        return BackgroundView.self
    }

}

extension PeopleArrayDataSource: DataSourceLifecycle {
    func didBecomeVisible() {
        selectElement(at: IndexPath(item: 0, section: 0))
    }
}

extension PeopleArrayDataSource: SelectionHandlingDataSource {

    var allowsMultipleSelection: Bool {
        return false
    }

    func selectionHandler(forElementAt indexPath: IndexPath) -> (() -> Void)? {
        return { print("Selected: \(self.selectedElements)") }
    }

    func deselectionHandler(forElementAt indexPath: IndexPath) -> (() -> Void)? {
        return { print("Selected: \(self.selectedElements)") }
    }

}

extension PeopleSectionedDataSource: SelectionHandlingDataSource {

    var allowsMultipleSelection: Bool {
        return true
    }

    func selectionHandler(forElementAt indexPath: IndexPath) -> (() -> Void)? {
        return { print("Selected: \(self.selectedElements)") }
    }

    func deselectionHandler(forElementAt indexPath: IndexPath) -> (() -> Void)? {
        return { print("Selected: \(self.selectedElements)") }
    }

}

class PeopleSectionedDataSource: SectionedDataSource<Person>, CollectionUIProvidingDataSource {

    var title: String?

    func sizingStrategy(for traitCollection: UITraitCollection, layoutSize: CGSize) -> CollectionUISizingStrategy {
        let columnCount = traitCollection.horizontalSizeClass == .compact ? 2 : 4
        return ColumnSizingStrategy(columnCount: columnCount, sizingMode: .automatic(isUniform: true))
    }

    func metrics(for section: Int, traitCollection: UITraitCollection, layoutSize: CGSize) -> CollectionUISectionMetrics {
        return CollectionUISectionMetrics(insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), horizontalSpacing: 8, verticalSpacing: 8)
    }

    func cellConfiguration(for indexPath: IndexPath) -> CollectionUIViewProvider {
        return CollectionUIViewProvider(prototype: PersonCell.fromNib, dequeueMethod: .nib) { cell, indexPath, _ in
            cell.prepare(person: self.element(at: indexPath))
        }
    }

    func footerConfiguration(for section: Int) -> CollectionUIViewProvider? {
        return CollectionUIViewProvider(prototype: FooterView.fromNib, dequeueMethod: .nib) { view, indexPath, _ in
            view.prepare(title: "\(self.numberOfElements(in: section)) items")
        }
    }

    func headerConfiguration(for section: Int) -> CollectionUIViewProvider? {
        return title.map { title in
            CollectionUIViewProvider(prototype: HeaderView.fromNib, dequeueMethod: .nib) { view, indexPath, _ in
                view.prepare(title: title)
            }
        }
    }

    func backgroundViewClass(for section: Int) -> UICollectionReusableView.Type? {
        return BackgroundView.self
    }

}

final class ListDataSource: ComposedDataSource, GlobalViewsProvidingDataSource {

    var placeholderView: UIView? {
        let view = UIActivityIndicatorView(style: .gray)
        view.startAnimating()
        return view
    }

    func globalHeaderConfiguration() -> CollectionUIViewProvider? {
        return CollectionUIViewProvider(prototype: GlobalHeaderView.fromNib, dequeueMethod: .nib) { _, _, _ in }
    }

    func globalFooterConfiguration() -> CollectionUIViewProvider? {
        return CollectionUIViewProvider(prototype: GlobalFooterView.fromNib, dequeueMethod: .nib) { _, _, _ in }
    }

}

final class PersonCell: UICollectionViewCell, ReusableViewNibLoadable {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var ageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        selectedBackgroundView = UIView(frame: .zero)
        selectedBackgroundView?.layer.cornerRadius = 6
        selectedBackgroundView?.layer.borderWidth = 1
        selectedBackgroundView?.layer.borderColor = UIColor.lightGray.cgColor
        selectedBackgroundView?.backgroundColor = UIColor(white: 0.88, alpha: 1)

        backgroundColor = .clear
    }

    public func prepare(person: Person) {
        nameLabel.text = person.name
        ageLabel.text = "\(person.age)"
    }

}

final class HeaderView: DataSourceHeaderFooterView, ReusableViewNibLoadable {

    @IBOutlet private weak var titleLabel: UILabel!

    public func prepare(title: String?) {
        backgroundColor = .lightGray
        titleLabel.text = title
    }

}

final class FooterView: DataSourceHeaderFooterView, ReusableViewNibLoadable {

    @IBOutlet private weak var titleLabel: UILabel!

    public func prepare(title: String?) {
        backgroundColor = .darkGray
        titleLabel.text = title
    }

}
