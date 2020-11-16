/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Atomics

fileprivate enum State: Int, AtomicValue {

    init?(value: Int) {
        switch value {
        case 0:
            self = .idle
        case 1:
            self = .halted
        case 2:
            self = .running
        default: return nil
        }
    }
    case idle, halted, running
}

public final class BatchEventProcessor<E, D: DataProvider, H: EventHandler>: EventProcessor, Runnable where D.Event == E, H.Event == E {
    typealias Event = E

    private let running = ManagedAtomic<State>(.idle)
    private let dataProvider: D
    private let sequenceBarrier: SequenceBarrier
    private let eventHandler: H

    public let sequence: Sequence = Sequence()

    public init(dataProvider: D, sequenceBarrier: SequenceBarrier, eventHandler: H) {
        self.dataProvider = dataProvider
        self.sequenceBarrier = sequenceBarrier
        self.eventHandler = eventHandler
    }

    public func run() {
        if running.compareExchange(expected: .idle, desired: .running, ordering: .sequentiallyConsistent).exchanged {
            sequenceBarrier.clearAlert()
            if running.load(ordering: .sequentiallyConsistent) == .running {
                defer { running.store(.idle, ordering: .sequentiallyConsistent) }
                processEvents()
            }
        } else {
            precondition(running.load(ordering: .sequentiallyConsistent) != .running, "thread is already running")
        }
    }

    public func halt() {
        running.store(.halted, ordering: .sequentiallyConsistent)
        sequenceBarrier.alert()
    }

    var isRunning: Bool {
        get {
            return running.load(ordering: .relaxed) == .running
        }
    }

    private func processEvents() {
        var event: E?
        var nextSequence = sequence.value + 1

        while true {
            do {
                let availableSequence = try sequenceBarrier.waitFor(sequence: nextSequence)

                repeat {
                    event = dataProvider.get(sequence: nextSequence)
                    eventHandler.onEvent(event!, sequence: nextSequence, endOfBatch: nextSequence == availableSequence)
                    nextSequence += 1
                } while nextSequence <= availableSequence

                sequence.value = availableSequence
            } catch is AlertError {
                if running.load(ordering: .sequentiallyConsistent) != .running {
                    break
                }
            } catch {
                sequence.value = nextSequence
                nextSequence += 1
            }

        }
    }
}
