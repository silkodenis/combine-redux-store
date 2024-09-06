import XCTest
import Combine
@testable import CombineReduxStore

final class StoreTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    func testInitialState() {
        let store = Store<String, Int>(initial: "001", feedbacks: [], reduce: { state, action in })
        XCTAssertEqual(store.state, "001", "Store should initialize with the provided initial state.")
    }
    
    func testDispatchActionUpdatesState() {
        let expectation = XCTestExpectation(description: "State should be updated after dispatching an action.")
        
        struct State {
            var value = 2
            
            mutating func reduce(_ action: Int) {
                value += action
            }
        }
        
        let store = Store<State, Int>(
            initial: State(value: 2),
            feedbacks: [],
            reduce: { state, action in
                //print("⚙️ Reducing state \(state) with action \(action)")
                state.reduce(action)
            }
        )
        
        store.$state
            .dropFirst()
            .sink { state in
                XCTAssertEqual(state.value, 5, "State should be updated after dispatching an action.")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        store.dispatch(action: 3)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFeedbackOutputPublishesActions() {
        let expectation = XCTestExpectation(description: "Feedback output should publish dispatched actions.")
        
        let store = Store<Any, Int>(
            initial: 0,
            feedbacks: [],
            reduce: { state, action in }
        )
        
        store.feedbackOutputPublisher
            .sink { action in
                XCTAssertEqual(action, 12, "Feedback output should publish the correct action.")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        store.dispatch(action: 12)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFeedbackLoopsAction() {
        let expectation = XCTestExpectation(description: "Feedback should loop actions into the store.")
        
        let initialState = 55
        
        let feedback = Feedback<Int, Int> { state in
            state
                .filter { $0 == 55 }
                .map { _ in 11 }
                .eraseToAnyPublisher()
        }
        
        let store = Store<Int, Int>(
            initial: initialState,
            feedbacks: [feedback],
            reduce: { state, action in
                state += action
            }
        )
        
        store.$state
            .dropFirst()
            .sink { state in
                XCTAssertEqual(state, 66, "State should be updated through feedback.")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}
