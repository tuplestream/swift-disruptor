/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import XCTest
@testable import Disruptor

final class SequenceTests: XCTestCase {

    private var sequenceGroup: SequenceGroup!
    private var sThree: Sequence!
    private var sSeven: Sequence!

    override func setUp() {
        sequenceGroup = SequenceGroup()
        sThree = Sequence(initialValue: 3)
        sSeven = Sequence(initialValue: 7)
    }

    func testShouldReturnMaxSequenceWhenEmptyGroup() {
        XCTAssertEqual(sequenceGroup.value, Int64.max)
    }

    // TODO
    func testShouldAddOneSequenceToGroup() {
        let sequence = Sequence(initialValue: 7)
        sequenceGroup.add(sequence)

        XCTAssertEqual(sequenceGroup.value, sequence.value)
    }

    func testShouldNotFailIfTryingToRemoveNotExistingSequence() {
        sequenceGroup.add(Sequence())
        sequenceGroup.add(Sequence())
        XCTAssertFalse(sequenceGroup.remove(Sequence()))
    }

    func testShouldReportTheMinimumSequenceForGroupOfTwo() {
        sequenceGroup.add(sSeven)
        sequenceGroup.add(sThree)

        XCTAssertEqual(sThree.value, sequenceGroup.value)
    }

    func testShouldReportSizeOfGroup() {
        let count = 3
        for _ in 0..<count {
            sequenceGroup.add(Sequence())
        }

        XCTAssertEqual(count, sequenceGroup.size)
    }

    func testShouldRemoveSequenceFromGroup() {
        sequenceGroup.add(sSeven)
        sequenceGroup.add(sThree)

        XCTAssertEqual(sThree.value, sequenceGroup.value)

        XCTAssertTrue(sequenceGroup.remove(sThree))
        XCTAssertEqual(sSeven.value, sequenceGroup.value)
        XCTAssertEqual(1, sequenceGroup.size)
    }

    func testShouldRemoveSequenceFromGroupWhereItBeenAddedMultipleTimes() {
        sequenceGroup.add(sThree)
        sequenceGroup.add(sSeven)
        sequenceGroup.add(sThree)

        XCTAssertEqual(sThree.value, sequenceGroup.value)

        XCTAssertTrue(sequenceGroup.remove(sThree))
        XCTAssertEqual(sSeven.value, sequenceGroup.value)
        XCTAssertEqual(1, sequenceGroup.size)
    }

    func testShouldSetGroupSequenceToSameValue() {
        sequenceGroup.add(sSeven)
        sequenceGroup.add(sThree)

        let expectedSequence: Int64 = 11
        sequenceGroup.value = expectedSequence

        XCTAssertEqual(expectedSequence, sThree.value)
        XCTAssertEqual(expectedSequence, sSeven.value)
        XCTAssertEqual(expectedSequence, sequenceGroup.value)
    }

    func testShouldAddWhileRunning() {
        // TODO
    }
}

class FixedSequenceGroupTests: XCTestCase {

    func testShouldReturnMinimumOf2Sequences() {
        let s1 = Sequence(initialValue: 34)
        let s2 = Sequence(initialValue: 47)
        let group = FixedSequenceGroup([s1, s2])

        XCTAssertEqual(34, group.value)
        s1.value = 35
        XCTAssertEqual(35, group.value)
        s1.value = 48
        XCTAssertEqual(47, group.value)
    }
}
