import Foundation
import ComposableArchitecture

extension MainView {
    struct State: Equatable {
        struct Field: Identifiable, Equatable, Hashable {
            let id: UUID = .init()
            var name: String
        }
        
        var fields = [Field]()
        
        mutating func add() {
            fields.append(.init(name: "New"))
        }
        
        mutating func remove() {
            guard !fields.isEmpty else { return }
            fields.removeLast()
        }
        
        mutating func update(_ text: String, _ index: Int) {
            fields[index].name = text
        }
    }
    
    enum Action: Equatable {
        case add,
             removeLast,
             updateText(String, Int)
    }
    
    struct Environment {}
    
    static let reducer = AnyReducer<State, Action, Environment>({ state, action, environment in
        switch action {
        case .add:
            state.add()
        case .removeLast:
            state.remove()
        case let .updateText(text, index):
            state.update(text, index)
        }
        return .none
    })
}
