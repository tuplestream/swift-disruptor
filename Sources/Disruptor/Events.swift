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

public protocol EventTranslator {
    associatedtype Event
    associatedtype Input
    func translateTo(_ event: Event, sequence: Int64, input: Input)
}

public protocol EventSink {
    associatedtype Event
    func publishEvent<E: EventTranslator>(translator: E, input: E.Input) where E.Event == Event
}
