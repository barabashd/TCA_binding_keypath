import SwiftUI
import ComposableArchitecture

// MARK: - Example 1: MainView using TCA where binding getter get called when it shouldn't (ex. add 1st element, then remove it and getter get called for an empty array)
struct MainView: View {
    let store: Store<State, Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                ForEachWithIndex(data: viewStore.fields) { index, field in
                    // Important to have HStack to reproduce this bug
                    HStack {
                        TextField(
                            "",
                            text: viewStore.binding(
                                get: \.fields[index].name, // crash!
                                // we may fix this with the next line but it's still not good to have useless UI updates
                                // { _ in field.name or viewStore.fields[index].name }
                                send: { Action.updateText($0, index) }
                            )
                        )
                        Text("---")
                    }
                }
                Button("Add new") { viewStore.send(.add) }
                Button("Remove last") { viewStore.send(.removeLast) }
            }
        }
    }
}

// MARK: - Example 2: MainView using native SwiftUI approach with @State (no crash)
//struct MainView: View {
//    let store: Store<State, Action>
//    @StateCopy var fields = [State.Field]()
//
//    var body: some View {
//        VStack {
//            ForEachWithIndex(data: fields) { index, field in
//                HStack {
//                    TextField(
//                        "",
//                        text: $fields[index].name
//                    )
//                    Text("Test")
//                }
//            }
//            Button("Add new") { fields.append(.init(name: "123")) }
//            Button("Remove last") { if !fields.isEmpty { fields.removeLast() } }
//        }
//    }
//}

// MARK: - Example 3: MainView using TCA where binding (new) that make key path solution safe (no crashes)
//struct MainView: View {
//    let store: Store<State, Action>
//
//    var body: some View {
//        WithViewStore(store) { viewStore in
//            VStack {
//                ForEachWithIndex(data: viewStore.fields) { index, field in
//                    HStack {
//                        TextField(
//                            "",
//                            // 'bindingNew' - a copy of 'binding' method
//                            text: viewStore.bindingNew(
//                                get: \.fields[index].name, // no crash
//                                send: { Action.updateText($0, index) }
//                            )
//                        )
//                        Text("---")
//                    }
//                }
//                Button("Add new") { viewStore.send(.add) }
//                Button("Remove last") { viewStore.send(.removeLast) }
//            }
//        }
//    }
//}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(
            store: .init(initialState: .init(fields: []),
                         reducer: MainView.reducer,
                         environment: MainView.Environment.init())
        )
    }
}

struct ForEachWithIndex<
    Data: RandomAccessCollection,
    Content: View
>: View where Data.Element: Identifiable, Data.Element: Hashable {
    let data: Data
    @ViewBuilder let content: (Data.Index, Data.Element) -> Content
    
    var body: some View {
        ForEach(Array(zip(data.indices, data)), id: \.1) { index, element in
            content(index, element)
        }
    }
}

// MARK: - TCA coppied methods for a test purpose

extension ViewStore {
    func bindingNew<Value>(
        get: @escaping (ViewState) -> Value,
        send valueToAction: @escaping (Value) -> ViewAction
    ) -> Binding<Value> {
        // @StateCopy - detailed State solution (resolve warning through ObservedObject)
        // @SwiftUI.State - has a waring "Accessing State's value outside of being installed on a View. This will result in a constant Binding of the initial value and will not update."
        @StateCopy var val = get(self.state)
        return .init(
            get: { $val.wrappedValue },
            set: { self.send(valueToAction($0)) }
        )
    }
    
    func bindingNewSafe<Value>(
        get: @escaping (ViewState) -> Value,
        send valueToAction: @escaping (Value) -> ViewAction
    ) -> Binding<Value> {
        @SwiftUI.State var val = get(self.state)
        return .init(
            get: { [weak self] in
                guard let self = self else { fatalError("Error") }
                return get(self.state)
            },
            set: { [weak self] in self?.send(valueToAction($0)) }
        )
    }
}

final fileprivate class ValueWrapper<V>: ObservableObject {
    var value: V {
        willSet { objectWillChange.send() }
    }
    
    init(_ value: V) {
        self.value = value
    }
}

// StateCopy - detailed copy of State propertyWrapper but with ObservedObject
// (resolve warning "Accessing State's value outside of being installed on a View. This will result in a constant Binding of the initial value and will not update.") inside and debugPrint for getter
@propertyWrapper fileprivate struct StateCopy<Value>: DynamicProperty {
    @ObservedObject private var box: ValueWrapper<Value>
    
    var wrappedValue: Value {
        get { return box.value }
        nonmutating set { box.value = newValue }
    }
    
    var projectedValue: Binding<Value> {
        .init(
            get: {
                debugPrint("will get")
                return wrappedValue
            },
            set: { wrappedValue = $0 }
        )
    }

    init(wrappedValue value: Value) {
        self._box = ObservedObject(wrappedValue: .init(value))
    }
}
