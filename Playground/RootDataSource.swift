import Composed

public final class RootDataSource: GlobalDataSource {

    public override func globalHeaderConfiguration() -> DataSourceUIConfiguration? {
        return DataSourceUIConfiguration(prototype: GlobalHeaderView.fromNib, dequeueSource: .nib) { _, _ in }
    }

}
