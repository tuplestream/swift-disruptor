/*
 Copyright 2020 TupleStream OÜ
 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation

extension Date {

    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }

}

protocol Benchmark {

    var name: String { get }
    func benchmarkRun()
}

extension Benchmark {

    func perform() {
        print("Starting \(name) benchmark run...")
        let startTime = Date()
        benchmarkRun()
        let totalRunTime = Date() - startTime

        print("Benchmark run for \(name) finished, took: \(totalRunTime)")
    }
}

DisruptorBenchmark().perform()
GCDBenchmark().perform()
