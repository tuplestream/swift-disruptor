/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation

protocol WaitStrategy {
    func waitFor(sequence: UInt64, cursor: Sequence, dependentSequence: Sequence, barrier: SequenceBarrier) throws -> UInt64
    func signalAllWhenBlocking()
}

final class SleepingWaitStrategy: WaitStrategy {

    private static let defaultRetries = 200
    private static let defaultSleep = 100

    private let retries: Int
    private let sleepTimeNanoseconds: Int

    init(retries: Int = SleepingWaitStrategy.defaultSleep, sleepTimeNanoseconds: Int = SleepingWaitStrategy.defaultSleep) {
        self.retries = retries
        self.sleepTimeNanoseconds = sleepTimeNanoseconds
    }

    func waitFor(sequence: UInt64, cursor: Sequence, dependentSequence: Sequence, barrier: SequenceBarrier) throws -> UInt64 {
        var availableSequence = dependentSequence.value
        var counter = retries

        while availableSequence < sequence {
            counter = applyWaitMethod(barrier: barrier, counter: &counter)
            availableSequence = dependentSequence.value
        }

        return availableSequence
    }

    func signalAllWhenBlocking() {
        // no-op
    }

    private func applyWaitMethod(barrier: SequenceBarrier, counter: inout Int) -> Int {
        // barrier.checkAlert() // TODO
        if counter > 100 {
            counter -= 1
        } else if counter > 0 {
            counter -= 1
            sched_yield()
        } else {
            Thread.sleep(forTimeInterval: 0.000001)
        }
        return counter
    }
}

