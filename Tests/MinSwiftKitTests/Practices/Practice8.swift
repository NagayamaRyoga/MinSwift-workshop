import Foundation
import XCTest
import FileCheck
@testable import MinSwiftKit

final class Practice8: XCTestCase {
    private let engine = Engine()

    // Don't worry, you already have everything 😈

    // 8-1
    func testCube() {
        let source = """
func cube(_ x: Double) -> Double {
    return x * x * x
}
"""
        try! engine.load(from: source)
        typealias FunctionType = @convention(c) (Double) -> Double
        try! engine.run("cube", of: FunctionType.self) { cube in
            XCTAssertEqual(cube(3), 27)
            XCTAssertEqual(cube(42), 74088)
        }
    }

    // 8-2
    func testFactorial() {
        let source = """
func factorial(_ n: Double) -> Double {
    if n < 1 {
        return 1
    } else {
        return n * factorial(n - 1)
    }
}
"""
        try! engine.load(from: source)
        typealias FunctionType = @convention(c) (Double) -> Double
        try! engine.run("factorial", of: FunctionType.self) { factorial in
            XCTAssertEqual(factorial(4), 24)
            XCTAssertEqual(factorial(6), 720)
            XCTAssertEqual(factorial(10), 3628800)
        }
    }

    // 8-3
    func testFibonacci() {
        let source = """
func fibonacci(_ n: Double) -> Double {
    if n < 2 {
        return n
    } else {
        return fibonacci(n - 1) + fibonacci(n - 2)
    }
}
"""
        try! engine.load(from: source)
        typealias FunctionType = @convention(c) (Double) -> Double
        try! engine.run("fibonacci", of: FunctionType.self) { fib in
            XCTAssertEqual(fib(10), 55)
            XCTAssertEqual(fib(20), 6765)
        }
    }

    func testLet() {
        let source = """
func double(_ n: Double) -> Double {
    let a: Double = n * 2.0;
    return a
}
"""
        try! engine.load(from: source)
        typealias FunctionType = @convention(c) (Double) -> Double
        try! engine.run("double", of: FunctionType.self) { double in
            XCTAssertEqual(double(10), 20)
            XCTAssertEqual(double(20), 40)
        }
    }

    func testLet2() {
        let source = """
func pentaple(_ n: Double) -> Double {
    let a: Double = n * 4.0;
    let b: Double = n + n;
    return a + b
}
"""
        try! engine.load(from: source)
        typealias FunctionType = @convention(c) (Double) -> Double
        try! engine.run("pentaple", of: FunctionType.self) { pentaple in
            XCTAssertEqual(pentaple(10), 60)
            XCTAssertEqual(pentaple(20), 120)
        }
    }

    func testExternalFunction() {
        let source = """
func printer(_ n: Double) -> Double {
    return printDouble(n)
}
"""
        try! engine.load(from: source)
        XCTAssertTrue(fileCheckOutput(of: .stderr, withPrefixes: ["ExternalFunction"]) {
            // ExternalFunction: ; ModuleID = 'main'
            // ExternalFunction-NEXT: source_filename = "main"
            // ExternalFunction: define double @printer(double) {
            // ExternalFunction-NEXT:     entry:
            // ExternalFunction-NEXT:     %calltmp = call double @printDouble(double %0)
            // ExternalFunction-NEXT:     ret double %calltmp
            // ExternalFunction-NEXT: }
            engine.dump()
        })
    }
}
