//
//  File.swift
//  
//
//  Created by Chris Mowforth on 12/04/2020.
//

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
