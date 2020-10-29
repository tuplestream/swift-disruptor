/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
protocol SequenceBarrier {
    func waitFor(sequence: Int64) throws -> Int64
    var cursor: Int64 { get }
}

final class ProcessingSequenceBarrier: SequenceBarrier {

    private let waitStrategy: WaitStrategy
    private let cursorSequence: Sequence
    private let dependentSequence: Sequence
    private let sequencer: Sequencer

    init(sequencer: Sequencer, waitStrategy: WaitStrategy, cursorSequence: Sequence, dependentSequences: [Sequence]) {
        self.sequencer = sequencer
        self.waitStrategy = waitStrategy
        self.cursorSequence = cursorSequence

        if dependentSequences.isEmpty {
            self.dependentSequence = cursorSequence
        } else {
            self.dependentSequence = FixedSequenceGroup(sequences: dependentSequences)
        }
    }

    func waitFor(sequence: Int64) throws -> Int64 {
        let availableSequence = try waitStrategy.waitFor(sequence: sequence, cursor: cursorSequence, dependentSequence: dependentSequence, barrier: self)
        if availableSequence < sequence {
            return availableSequence
        }

        return sequencer.getHighestPublishedSequence(lowerBound: sequence, availableSequence: availableSequence)
    }

    var cursor: Int64 {
        get {
            return cursorSequence.value
        }
    }
}
