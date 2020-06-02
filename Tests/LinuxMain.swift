import XCTest

import DisruptorTests

var tests = [XCTestCaseEntry]()
tests += DisruptorTests.__allTests()

XCTMain(tests)
