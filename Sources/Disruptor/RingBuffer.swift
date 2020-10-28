/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation

public final class RingBuffer<E>: Cursored, Sequenced {

    var bufferSize: Int

    var remainingCapacity: UInt64


    init(_ factory: () -> E, sequencer: Sequencer) {
        bufferSize = 0
        remainingCapacity = 0
    }

    func hasAvailableCapacity(required: Int) -> Bool {
        return true
    }

    func next() -> UInt64 {
        return 0
    }

    func next(_ n: Int) -> UInt64 {
        return 0
    }

    func publish(_ sequence: UInt64) {

    }

    func publish(low: UInt64, high: UInt64) {

    }


//    private let sequencer: Sequencer

    var cursor: UInt64 {
        get {
//            return sequencer.cursor
            return 0
        }
    }


}
