/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation

public protocol WaitStrategy {
    func waitFor(sequence: Int64, cursor: Sequence, dependentSequence: Sequence, barrier: SequenceBarrier) throws -> Int64
    func signalAllWhenBlocking()
}

public final class BlockingWaitStrategy: WaitStrategy, CustomStringConvertible {

    private let lock: UnsafeMutablePointer<pthread_mutex_t>
    private let condition: UnsafeMutablePointer<pthread_cond_t>

    init() {
        self.lock = UnsafeMutablePointer.allocate(capacity: 1)
        pthread_mutex_init(lock, nil)
        self.condition = UnsafeMutablePointer.allocate(capacity: 1)
        pthread_cond_init(condition, nil)
    }

    deinit {
        pthread_mutex_destroy(lock)
        pthread_cond_destroy(condition)
    }

    public var description: String {
        get {
            return "BlockingWaitStrategy(mutex=\(lock.pointee))"
        }
    }

    public func waitFor(sequence: Int64, cursor: Sequence, dependentSequence: Sequence, barrier: SequenceBarrier) throws -> Int64 {
        if cursor.value < sequence {
            pthread_mutex_lock(lock)
            while cursor.value < sequence {
                try barrier.checkAlert()
                pthread_cond_wait(condition, lock)
            }
            pthread_mutex_unlock(lock)
        }

        var availableSequence: Int64
        repeat {
            try barrier.checkAlert()
            // TODO- figure out how to introduce __mm_pause or similar to mitigate cpu load from spinning here
            // see https://github.com/tuplestream/swift-disruptor/issues/2
            availableSequence = dependentSequence.value
        } while availableSequence < sequence
        return availableSequence
    }

    public func signalAllWhenBlocking() {
        pthread_mutex_lock(lock)
        defer { pthread_mutex_unlock(lock) }
        pthread_cond_signal(condition)
    }

}

public final class SleepingWaitStrategy: WaitStrategy, CustomStringConvertible {

    private static let defaultRetries = 200
    private static let defaultSleep = 100

    private let retries: Int
    private let sleepTimeNanoseconds: Int

    init(retries: Int = SleepingWaitStrategy.defaultSleep, sleepTimeNanoseconds: Int = SleepingWaitStrategy.defaultSleep) {
        self.retries = retries
        self.sleepTimeNanoseconds = sleepTimeNanoseconds
    }

    public var description: String {
        get {
            return "SleepingWaitStrategy(retries=\(retries) sleepTimeNanoseconds=\(sleepTimeNanoseconds))"
        }
    }

    public func waitFor(sequence: Int64, cursor: Sequence, dependentSequence: Sequence, barrier: SequenceBarrier) throws -> Int64 {
        var availableSequence = dependentSequence.value
        var counter = retries

        while availableSequence < sequence {
            counter = try applyWaitMethod(barrier: barrier, counter: &counter)
            availableSequence = dependentSequence.value
        }

        return availableSequence
    }

    public func signalAllWhenBlocking() {
        // no-op
    }

    private func applyWaitMethod(barrier: SequenceBarrier, counter: inout Int) throws -> Int {
        try barrier.checkAlert()

        if counter > 100 {
            counter -= 1
        } else if counter > 0 {
            counter -= 1
            sched_yield()
        } else {
            Thread.sleep(forTimeInterval: 0.0000001)
        }
        return counter
    }
}

