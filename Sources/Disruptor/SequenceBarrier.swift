protocol SequenceBarrier {
    func waitFor(sequence: UInt64) throws -> UInt64
    func getCursor() -> UInt64
}

final class ProcessingSequenceBarrier: SequenceBarrier {

    private let waitStrategy: WaitStrategy
    private let cursorSequence: Sequence
    private let sequencer: Sequencer

    init(waitStrategy: WaitStrategy, cursorSequence: Sequence, sequencer: Sequencer) {
        self.waitStrategy = waitStrategy
        self.cursorSequence = cursorSequence
        self.sequencer = sequencer
    }

    func waitFor(sequence: UInt64) throws -> UInt64 {
        let availableSequence = try waitStrategy.waitFor(sequence: sequence, cursor: cursorSequence, barrier: self)
        if availableSequence < sequence {
            return availableSequence
        }

        return sequencer.getHighestPublishedSequence(nextSequence: sequence, availableSequence: availableSequence)
    }

    func getCursor() -> UInt64 {
        return cursorSequence.get()
    }
}
