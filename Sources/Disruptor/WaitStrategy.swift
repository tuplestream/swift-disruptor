protocol WaitStrategy {
    func waitFor(sequence: UInt64, cursor: Sequence, barrier: SequenceBarrier) throws -> UInt64
    func signalAllWhenBlocking()
}