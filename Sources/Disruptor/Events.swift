/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
public protocol EventFactory {
    associatedtype Event
    func newInstance() -> Event
}

public protocol EventHandler {
    associatedtype Event
    func onEvent(_ event: Event, sequence: Int64, endOfBatch: Bool)
}
