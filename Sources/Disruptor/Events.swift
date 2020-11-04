/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Atomics

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
    func translateTo(_ event: inout Event, sequence: Int64, input: Input)
}

public protocol EventSink {
    associatedtype Event
    func publishEvent<E: EventTranslator>(translator: E, input: E.Input) where E.Event == Event
}

protocol EventProcessor {
    func run()
    var sequence: Sequence { get }
    func halt()
    var isRunning: Bool { get }
}

final class NoOpEventProcessor: EventProcessor {

    class SequencerFollowingSequence<T,U: EventFactory>: Sequence where U.Event == T {

        private let ringBuffer: RingBuffer<T,U>

        init(_ ringBuffer: RingBuffer<T, U>) {
            self.ringBuffer = ringBuffer
            super.init(initialValue: MultiProducerSequencer.initialCursorValue)
        }

        override var value: Int64 {
            get {
                return ringBuffer.cursor
            }
            set(newValue) {
                super.value = newValue
            }
        }
    }

    private let running = ManagedAtomic<Bool>(false)
    private(set) var sequence: Sequence

    init<T, U>(_ ringBuffer: RingBuffer<T,U>) {
        self.sequence = SequencerFollowingSequence<T,U>(ringBuffer)
    }

    func halt() {
        running.store(false, ordering: .relaxed)
    }

    func run() {
        precondition(running.compareExchange(expected: false, desired: true, ordering: .acquiringAndReleasing).exchanged,
                     "thread is already running")
    }

    var isRunning: Bool {
        get {
            return running.load(ordering: .relaxed)
        }
    }
}
