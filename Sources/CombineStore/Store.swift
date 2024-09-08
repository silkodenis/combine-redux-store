/*
 * Copyright (c) [2024] [Denis Silko]
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://github.com/silkodenis/combine-redux-store
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import Combine

public class Store<State, Action>: ObservableObject {
    @Published public private(set) var state: State
    private let userInput = PassthroughSubject<Action, Never>()
    private let feedbackOutput = PassthroughSubject<Action, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        initial state: State,
        feedbacks: [Feedback<State, Action>],
        reduce: @escaping (inout State, Action) -> Void
    ) {
        self.state = state
        
        Self.feedbackLoop(
            initial: state,
            reduce: reduce,
            feedbacks: feedbacks,
            userInput: userInput,
            feedbackOutput: feedbackOutput
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] state in
            self?.state = state
        }
        .store(in: &cancellables)
    }
    
    public func dispatch(action: Action) {
        userInput.send(action)
    }
    
    public var feedbackOutputPublisher: AnyPublisher<Action, Never> {
        feedbackOutput.eraseToAnyPublisher()
    }
    
    // MARK: - Private
    
    private static func feedbackLoop(
        initial: State,
        reduce: @escaping (inout State, Action) -> Void,
        feedbacks: [Feedback<State, Action>],
        userInput: PassthroughSubject<Action, Never>,
        feedbackOutput: PassthroughSubject<Action, Never>
    ) -> AnyPublisher<State, Never> {
        
        let state = CurrentValueSubject<State, Never>(initial)
        let actions = feedbacks.map { feedback in
            feedback.execute(state.eraseToAnyPublisher())
        }
        
        return Publishers.MergeMany(actions + [userInput.eraseToAnyPublisher()])
            .scan(initial) { state, event in
                var state = state
                reduce(&state, event)
                feedbackOutput.send(event)
                return state
            }
            .handleEvents(receiveOutput: state.send)
            .eraseToAnyPublisher()
    }
}
