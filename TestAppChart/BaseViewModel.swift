//<BaseFundsViewModel>
import Combine
import Foundation

class BaseViewModel: ObservableObject, Bindable {
    var cancellables = Set<AnyCancellable>()
    
    init() {
   
    }
    
    /// This method is called whenever the user logs in.
    /// Subclasses should override this method to perform specific actions upon login.
    func onUserLoggedIn() {
        // Override in subclasses
    }
    
    func bind<Value, Object: ObservableObject>(
        _ publisher: Published<Value>.Publisher,
        to keyPath: ReferenceWritableKeyPath<Object, Value>,
        on object: Object
    ) {
        publisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak object] newValue in
                object?[keyPath: keyPath] = newValue
            })
            .store(in: &cancellables)
    }
}

protocol Bindable: AnyObject {
    var cancellables: Set<AnyCancellable> { get set }
    
    func bind<Value, Object: ObservableObject>(
        _ publisher: Published<Value>.Publisher,
        to keyPath: ReferenceWritableKeyPath<Object, Value>,
        on object: Object
    )
}

//</BaseFundsViewModel>
