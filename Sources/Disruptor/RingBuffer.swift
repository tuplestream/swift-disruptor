//
//  File.swift
//  
//
//  Created by Chris Mowforth on 12/04/2020.
//

import Foundation

public final class RingBuffer: Cursored, Sequenced {

    private let sequencer: Sequencer

    var cursor: UInt64 {
        get {
            return sequencer.cursor
        }
    }


}
