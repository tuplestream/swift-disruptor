/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation
import Dispatch
import Disruptor
import Atomics

print("Starting benchmark...")

let queue = DispatchQueue(label: "justTesting")
var counter = 0

let max = 100000000
for _ in 0..<max {
    queue.async {
        counter += 1
    }
    // comment out to stall submissions
//    Thread.sleep(forTimeInterval: 0.0000001)
}

print("done queuing")

repeat {
    Thread.sleep(forTimeInterval: 0.1)
} while counter < max

print("done")
