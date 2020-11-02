/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import _Volatile

protocol SequenceBarrier {
    func waitFor(sequence: Int64) throws -> Int64
    var cursor: Int64 { get }
    func alert()
    func clearAlert()
    func checkAlert() throws
}

struct AlertError: Error {}

final class ProcessingSequenceBarrier: SequenceBarrier {

    private let waitStrategy: WaitStrategy
    private let cursorSequence: Sequence
    private let dependentSequence: Sequence
    private let sequencer: Sequencer

    // the Java implementation uses a boolean here but it's simpler to elide the
    // type conversions since we're using volatile shim to read & write. It's not
    // referenced in many places anyway
    private var alerted: UnsafeMutablePointer<Int>

    init(sequencer: Sequencer, waitStrategy: WaitStrategy, cursorSequence: Sequence, dependentSequences: [Sequence]) {
        self.sequencer = sequencer
        self.waitStrategy = waitStrategy
        self.cursorSequence = cursorSequence
        self.alerted = UnsafeMutablePointer.allocate(capacity: 1)
        alerted.initialize(to: 0)

        if dependentSequences.isEmpty {
            self.dependentSequence = cursorSequence
        } else {
            self.dependentSequence = FixedSequenceGroup(sequences: dependentSequences)
        }
    }

    deinit {
        alerted.deallocate()
    }

    func waitFor(sequence: Int64) throws -> Int64 {
        let availableSequence = try waitStrategy.waitFor(sequence: sequence, cursor: cursorSequence, dependentSequence: dependentSequence, barrier: self)
        if availableSequence < sequence {
            return availableSequence
        }

        return sequencer.getHighestPublishedSequence(lowerBound: sequence, availableSequence: availableSequence)
    }

    func alert() {
        volatile_store_int(UnsafeMutableRawPointer(alerted), 1)
    }

    func clearAlert() {
        volatile_store_int(UnsafeMutableRawPointer(alerted), 0)
    }

    func checkAlert() throws {
        if volatile_load_int(UnsafeMutableRawPointer(alerted)) == 1 {
            throw AlertError()
        }
    }

    var cursor: Int64 {
        get {
            return cursorSequence.value
        }
    }
}
