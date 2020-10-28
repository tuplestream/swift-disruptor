/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
protocol SequenceBarrier {
    func waitFor(sequence: UInt64) throws -> UInt64
    var cursor: UInt64 { get }
}

final class ProcessingSequenceBarrier: SequenceBarrier {

    private let waitStrategy: WaitStrategy
    private let cursorSequence: Sequence
    private let dependentSequence: Sequence
    private let sequencer: Sequencer

    init(waitStrategy: WaitStrategy, cursorSequence: Sequence, dependentSequence: Sequence, sequencer: Sequencer) {
        self.waitStrategy = waitStrategy
        self.cursorSequence = cursorSequence
        self.dependentSequence = dependentSequence
        self.sequencer = sequencer
    }

    func waitFor(sequence: UInt64) throws -> UInt64 {
        let availableSequence = try waitStrategy.waitFor(sequence: sequence, cursor: cursorSequence, dependentSequence: dependentSequence, barrier: self)
        if availableSequence < sequence {
            return availableSequence
        }

        return sequencer.getHighestPublishedSequence(lowerBound: sequence, availableSequence: availableSequence)
    }

    var cursor: UInt64 {
        get {
            return cursorSequence.value
        }
    }
}
