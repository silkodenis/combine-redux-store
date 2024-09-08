import XCTest
import Combine
@testable import CombineStore

final class FeedbackTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()

    func testPreventDuplicate() {
        let expectation = XCTestExpectation(description: "Effect should not be duplicated")
        var effectExecutedCount = 0
        
        let feedback = Feedback<String, String>(effects: { state in
            effectExecutedCount += 1
            
            return Just("Action: \(state)")
                .delay(for: .seconds(0.1), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }, preventDuplicate: true)
        
        let statePublisher = PassthroughSubject<String, Never>()
        
        feedback.execute(statePublisher.eraseToAnyPublisher())
            .sink { _ in }
            .store(in: &cancellables)
        
        statePublisher.send("State1")
        statePublisher.send("State2")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(effectExecutedCount, 1, "Effect should only have been executed once")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAllowDuplicate() {
        let expectation = XCTestExpectation(description: "Effect should be allowed to duplicate")
        var effectExecutedCount = 0
        
        let feedback = Feedback<String, String>(effects: { state in
            effectExecutedCount += 1
            
            return Just("Action: \(state)")
                .delay(for: .seconds(0.1), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }, preventDuplicate: false)
        
        let statePublisher = PassthroughSubject<String, Never>()
        
        feedback.execute(statePublisher.eraseToAnyPublisher())
            .sink { _ in }
            .store(in: &cancellables)
        
        statePublisher.send("State1")
        statePublisher.send("State2")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(effectExecutedCount, 2, "Effect should have been executed twice")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    func testEffectCompletion() {
        let expectation = XCTestExpectation(description: "Effect should complete and allow subsequent actions")
        var effectExecutedCount = 0
        
        let feedback = Feedback<String, String>(effects: { state in
            effectExecutedCount += 1
            
            return Just("Action: \(state)")
                .delay(for: .seconds(0.1), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }, preventDuplicate: true)
        
        let statePublisher = PassthroughSubject<String, Never>()
        
        feedback.execute(statePublisher.eraseToAnyPublisher())
            .sink { _ in }
            .store(in: &cancellables)
        
        statePublisher.send("State1")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            statePublisher.send("State2")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                XCTAssertEqual(effectExecutedCount, 2, "Effect should have been executed twice after completion")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
