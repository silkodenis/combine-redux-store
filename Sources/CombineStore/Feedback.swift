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

import Combine
import Dispatch

public struct Feedback<State, Action> {
    let execute: (AnyPublisher<State, Never>) -> AnyPublisher<Action, Never>
}

public extension Feedback {
    init<Effect: Publisher>(
        effects: @escaping (State) -> Effect,
        preventDuplicate: Bool = true
    )
    where Effect.Output == Action, Effect.Failure == Never {
        if preventDuplicate {
            let isExecuting = Atomic(false)
            
            self.execute = { state in
                state
                    .filter { _ in !isExecuting.value }
                    .map { currentState in
                        isExecuting.value = true
                        
                        return effects(currentState)
                            .handleEvents(receiveCompletion: { _ in
                                isExecuting.value = false
                            })
                            .eraseToAnyPublisher()
                    }
                    .switchToLatest()
                    .eraseToAnyPublisher()
            }
        } else {
            self.execute = { state in
                state
                    .map { effects($0) }
                    .switchToLatest()
                    .eraseToAnyPublisher()
            }
        }
    }
}
