/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation

public protocol Runnable {
    func run()
}

public protocol Executor {
    func execute(_ runnable: Runnable)
}

fileprivate final class BasicExecutor: Executor {

    private var threads: [Thread] = []

    func execute(_ runnable: Runnable) {
        
    }

}

public class Disruptor<E> {

    /// Defines producer types to support creation of RingBuffer with correct sequencer and publisher.
    public enum ProducerType {
        case single, multi
    }

    public let ringBuffer: RingBuffer<E>
    private let executor: Executor

//    public init<F: EventFactory>(eventFactory: F, ringBufferSize: Int32) {
//    }

    private init(_ ringBuffer: RingBuffer<E>, _ executor: Executor) {
        self.ringBuffer = ringBuffer
        self.executor = executor
    }
}
