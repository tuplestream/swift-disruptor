/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/

/// Defines producer types to support creation of RingBuffer with correct sequencer and publisher.
public enum ProducerType {
    case single, multi
}

public class Disruptor<E> {

//    public let ringBuffer: RingBuffer<T>

    public init<F: EventFactory>(eventFactory: () -> F, ringBufferSize: Int) where F.Event == E {
//        self.ringBuffer =
    }
}
