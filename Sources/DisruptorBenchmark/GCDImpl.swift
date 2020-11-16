/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Atomics
import Dispatch
import Foundation

class GCDBenchmark: Benchmark {

    let name = "GCD"

    func benchmarkRun() {
        let queue = DispatchQueue(label: "GCDBenchmark")
        var counter = 0

        let max = 10240000
        for _ in 0..<max {
            queue.async {
                counter += 1
            }
        }

        repeat {
            Thread.sleep(forTimeInterval: 0.001)
        } while counter < max
    }


}
