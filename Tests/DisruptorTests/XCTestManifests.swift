#if !canImport(ObjectiveC)
import XCTest

extension FixedSequenceGroupTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__FixedSequenceGroupTests = [
        ("testShouldReturnMinimumOf2Sequences", testShouldReturnMinimumOf2Sequences),
    ]
}

extension MultiProducerSequencerTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__MultiProducerSequencerTests = [
        ("testShouldOnlyAllowMessagesToBeAvailableIfSpecificallyPublished", testShouldOnlyAllowMessagesToBeAvailableIfSpecificallyPublished),
    ]
}

extension RingBufferTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__RingBufferTests = [
        ("testShouldAddAndRemoveSequences", testShouldAddAndRemoveSequences),
        ("testShouldClaimAndGet", testShouldClaimAndGet),
        ("testShouldClaimAndGetInSeparateThread", testShouldClaimAndGetInSeparateThread),
        ("testShouldClaimAndGetMultipleMessages", testShouldClaimAndGetMultipleMessages),
        ("testShouldNotPublishEventsIfBatchIsLargerThanRingBuffer", testShouldNotPublishEventsIfBatchIsLargerThanRingBuffer),
        ("testShouldPreventPublishersOvertakingEventProcessorWrapPoint", testShouldPreventPublishersOvertakingEventProcessorWrapPoint),
        ("testShouldPreventWrapping", testShouldPreventWrapping),
        ("testShouldPublishEvent", testShouldPublishEvent),
        ("testShouldThrowExceptionIfBufferIsFull", testShouldThrowExceptionIfBufferIsFull),
        ("testShouldWrap", testShouldWrap),
    ]
}

extension SequenceBarrierTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__SequenceBarrierTests = [
        ("testShouldInterruptDuringBusySpin", testShouldInterruptDuringBusySpin),
        ("testShouldSetAndClearAlertStatus", testShouldSetAndClearAlertStatus),
        ("testShouldWaitForWorkCompleteWhereAllWorkersAreBlockedOnRingBuffer", testShouldWaitForWorkCompleteWhereAllWorkersAreBlockedOnRingBuffer),
        ("testShouldWaitForWorkCompleteWhereCompleteWorkThresholdIsAhead", testShouldWaitForWorkCompleteWhereCompleteWorkThresholdIsAhead),
        ("testShouldWaitForWorkCompleteWhereCompleteWorkThresholdIsBehind", testShouldWaitForWorkCompleteWhereCompleteWorkThresholdIsBehind),
    ]
}

extension SequenceTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__SequenceTests = [
        ("testShouldAddOneSequenceToGroup", testShouldAddOneSequenceToGroup),
        ("testShouldAddWhileRunning", testShouldAddWhileRunning),
        ("testShouldNotFailIfTryingToRemoveNotExistingSequence", testShouldNotFailIfTryingToRemoveNotExistingSequence),
        ("testShouldRemoveSequenceFromGroup", testShouldRemoveSequenceFromGroup),
        ("testShouldRemoveSequenceFromGroupWhereItBeenAddedMultipleTimes", testShouldRemoveSequenceFromGroupWhereItBeenAddedMultipleTimes),
        ("testShouldReportSizeOfGroup", testShouldReportSizeOfGroup),
        ("testShouldReportTheMinimumSequenceForGroupOfTwo", testShouldReportTheMinimumSequenceForGroupOfTwo),
        ("testShouldReturnMaxSequenceWhenEmptyGroup", testShouldReturnMaxSequenceWhenEmptyGroup),
        ("testShouldSetGroupSequenceToSameValue", testShouldSetGroupSequenceToSameValue),
    ]
}

extension SequencerTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__SequencerTests = [
        ("testShouldBatchClaim", testShouldBatchClaim),
        ("testShouldClaimSpecificSequence", testShouldClaimSpecificSequence),
        ("testShouldHoldUpPublisherWhenBufferIsFull", testShouldHoldUpPublisherWhenBufferIsFull),
        ("testShouldIndicateHasAvailableCapacity", testShouldIndicateHasAvailableCapacity),
        ("testShouldIndicateNoAvailableCapacity", testShouldIndicateNoAvailableCapacity),
        ("testShouldNotBeAvailableUntilPublished", testShouldNotBeAvailableUntilPublished),
        ("testShouldNotifyWaitStrategyOnPublish", testShouldNotifyWaitStrategyOnPublish),
        ("testShouldNotifyWaitStrategyOnPublishBatch", testShouldNotifyWaitStrategyOnPublishBatch),
        ("testShouldStartWithInitialValue", testShouldStartWithInitialValue),
        ("testShouldTryNext", testShouldTryNext),
        ("testShouldWaitOnPublication", testShouldWaitOnPublication),
    ]
}

extension VolatileTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__VolatileTests = [
        ("testVolatileLoadStore", testVolatileLoadStore),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(FixedSequenceGroupTests.__allTests__FixedSequenceGroupTests),
        testCase(MultiProducerSequencerTests.__allTests__MultiProducerSequencerTests),
        testCase(RingBufferTests.__allTests__RingBufferTests),
        testCase(SequenceBarrierTests.__allTests__SequenceBarrierTests),
        testCase(SequenceTests.__allTests__SequenceTests),
        testCase(SequencerTests.__allTests__SequencerTests),
        testCase(VolatileTests.__allTests__VolatileTests),
    ]
}
#endif
