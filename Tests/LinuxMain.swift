import XCTest

import swift_disruptorTests

var tests = [XCTestCaseEntry]()
tests += DisruptorTests.allTests()
XCTMain(tests)
