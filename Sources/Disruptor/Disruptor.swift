/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Atomics
import Foundation

public protocol Runnable {
    func run()
    func halt()
}

public protocol Executor {
    func execute(_ runnable: Runnable)
}

fileprivate final class RunnableHolder: Thread {

    private let runnable: Runnable

    init(_ runnable: Runnable) {
        self.runnable = runnable
    }

    override func main() {
        runnable.run()
    }
}

fileprivate final class BasicExecutor: Executor {

    private var threads: [RunnableHolder] = []

    func execute(_ runnable: Runnable) {
        let holder = RunnableHolder(runnable)
        holder.start()
        threads.append(holder)
    }

}

public class Disruptor<E> {

    /// Defines producer types to support creation of RingBuffer with correct sequencer and publisher.
    public enum ProducerType {
        case single, multi
    }

    public let ringBuffer: RingBuffer<E>
    private let executor: Executor
    private let started = ManagedAtomic<Bool>(false)
    private var consumers: [EventProcessor & Runnable] = []

    public convenience init<F: EventFactory>(eventFactory: F, ringBufferSize: Int32, producerType: ProducerType = .multi) where F.Event == E {
        let rb: RingBuffer<E>
        if producerType == .multi {
            rb = RingBuffer.createMultiProducer(factory: eventFactory, bufferSize: ringBufferSize)
        } else {
            rb = RingBuffer.createSingleProducer(factory: eventFactory, bufferSize: ringBufferSize)
        }
        self.init(rb, BasicExecutor())
    }

    private init(_ ringBuffer: RingBuffer<E>, _ executor: Executor) {
        self.ringBuffer = ringBuffer
        self.executor = executor
    }

    public func handleEventsWith<H: EventHandler>(eventHandlers: [H]) where H.Event == E {
        checkNotStarted()

        let barrier = ringBuffer.newBarrier(sequencesToTrack: [])
//        var processorSequences: [Sequence] = []

        for handler in eventHandlers {
            let bep = BatchEventProcessor(dataProvider: ringBuffer, sequenceBarrier: barrier, eventHandler: handler)
//            processorSequences.append(bep.sequence)
            consumers.append(bep)
        }
    }

    public func start() -> RingBuffer<E> {
        checkNotStarted()
        for consumer in consumers {
            executor.execute(consumer)
        }

        return ringBuffer
    }

    public func halt() {
        for consumer in consumers {
            consumer.halt()
        }
    }

    public func publishEvent<T: EventTranslator>(_ eventTranslator: T, input: T.Input) where T.Event == E {
        ringBuffer.publishEvent(translator: eventTranslator, input: input)
    }

    public func publishEvents<T: EventTranslator>(_ eventTranslator: T, input: [T.Input]) where T.Event == E {
        ringBuffer.publishEvents(translator: eventTranslator, input: input)
    }

    private func checkNotStarted() {
        precondition(!started.load(ordering: .relaxed), "All event handlers must be added before calling starts.")
    }
}
