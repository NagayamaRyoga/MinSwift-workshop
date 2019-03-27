import Foundation
import XCTest
import FileCheck
@testable import MinSwiftKit

final class Practice7: ParserTestCase {
    // 7-1
    func testParsingComparisonOperator() {
        load("a < b + 20")
        // lhs: a
        // rhs:
        //     lhs: b
        //     rhs: 20
        //     operator: +
        // operator: <

        let node = parser.parseExpression()
        XCTAssertTrue(node is BinaryExpressionNode)
        let comparison = node as! BinaryExpressionNode
        XCTAssertTrue(comparison.lhs is VariableNode)
        XCTAssertTrue(comparison.rhs is BinaryExpressionNode)

        let rhsNode = comparison.rhs as! BinaryExpressionNode
        XCTAssertTrue(rhsNode.lhs is VariableNode)
        XCTAssertTrue(rhsNode.rhs is NumberNode)
        XCTAssertEqual(rhsNode.operator, .addition)
    }

    // 7-1ex
    func testParsingComparisonOperatorExLE() {
        load("a <= 10")
        // lhs: a
        // rhs: 10
        // operator: <=

        let node = parser.parseExpression()
        XCTAssertTrue(node is BinaryExpressionNode)
        let comparison = node as! BinaryExpressionNode
        XCTAssertTrue(comparison.operator == .lessEqual)
        XCTAssertTrue(comparison.lhs is VariableNode)
        XCTAssertTrue(comparison.rhs is NumberNode)
    }
    func testParsingComparisonOperatorExGT() {
        load("a > 10")
        // lhs: a
        // rhs: 10
        // operator: >

        let node = parser.parseExpression()
        XCTAssertTrue(node is BinaryExpressionNode)
        let comparison = node as! BinaryExpressionNode
        XCTAssertTrue(comparison.operator == .greaterThan)
        XCTAssertTrue(comparison.lhs is VariableNode)
        XCTAssertTrue(comparison.rhs is NumberNode)
    }
    func testParsingComparisonOperatorExGE() {
        load("a >= 10")
        // lhs: a
        // rhs: 10
        // operator: >=

        let node = parser.parseExpression()
        XCTAssertTrue(node is BinaryExpressionNode)
        let comparison = node as! BinaryExpressionNode
        XCTAssertTrue(comparison.operator == .greaterEqual)
        XCTAssertTrue(comparison.lhs is VariableNode)
        XCTAssertTrue(comparison.rhs is NumberNode)
    }
    func testParsingComparisonOperatorExEq() {
        load("a == 10")
        // lhs: a
        // rhs: 10
        // operator: ==

        let node = parser.parseExpression()
        XCTAssertTrue(node is BinaryExpressionNode)
        let comparison = node as! BinaryExpressionNode
        XCTAssertTrue(comparison.operator == .equal)
        XCTAssertTrue(comparison.lhs is VariableNode)
        XCTAssertTrue(comparison.rhs is NumberNode)
    }
    func testParsingComparisonOperatorExNe() {
        load("a != 10")
        // lhs: a
        // rhs: 10
        // operator: !=

        let node = parser.parseExpression()
        XCTAssertTrue(node is BinaryExpressionNode)
        let comparison = node as! BinaryExpressionNode
        XCTAssertTrue(comparison.operator == .notEqual)
        XCTAssertTrue(comparison.lhs is VariableNode)
        XCTAssertTrue(comparison.rhs is NumberNode)
    }

    // 7-2
    func testParsingIfElse() {
        load("""
    if a < 10 {
        foo(a: a)
    } else {
        foo(a: a + 10)
    }
    """)

        let node = parser.parseIfElse()

        let ifNode = node as! IfElseNode
        XCTAssertTrue(ifNode.condition is BinaryExpressionNode)
        let condition = ifNode.condition as! BinaryExpressionNode
        XCTAssertTrue(condition.lhs is VariableNode)
        XCTAssertTrue(condition.rhs is NumberNode)

        let thenBlock = ifNode.then
        XCTAssertTrue(thenBlock is CallExpressionNode)
        XCTAssertEqual((thenBlock as! CallExpressionNode).callee, "foo")

        let elseBlock = ifNode.else
        XCTAssertTrue(elseBlock is CallExpressionNode)
        XCTAssertEqual((elseBlock as! CallExpressionNode).callee, "foo")
    }

    // 7-2ex
    func testParsingIf() {
        load("""
    if a < 10 {
        foo(a: a)
    }
    """)

        let node = parser.parseIfElse()

        let ifNode = node as! IfElseNode
        XCTAssertTrue(ifNode.condition is BinaryExpressionNode)
        let condition = ifNode.condition as! BinaryExpressionNode
        XCTAssertTrue(condition.lhs is VariableNode)
        XCTAssertTrue(condition.rhs is NumberNode)

        let thenBlock = ifNode.then
        XCTAssertTrue(thenBlock is CallExpressionNode)
        XCTAssertEqual((thenBlock as! CallExpressionNode).callee, "foo")

        let elseBlock = ifNode.else
        XCTAssertNil(elseBlock)
    }

    // 7-3
    func testGenerateCompOperator() {
        let variableNode = VariableNode(identifier: "a")
        let numberNode = NumberNode(value: 10)
        let body = BinaryExpressionNode(.lessThan, lhs: variableNode, rhs: numberNode)
        let node = FunctionNode(name: "main",
                                arguments: [.init(label: nil, variableName: "a")],
                                returnType: .double,
                                body: body)

        let buildContext = BuildContext()
        build([node], context: buildContext)
        XCTAssertTrue(fileCheckOutput(of: .stderr, withPrefixes: ["CompOperator"]) {
            // CompOperator: ; ModuleID = 'main'
            // CompOperator-NEXT: source_filename = "main"

            // CompOperator: define double @main(double) {
            // CompOperator-NEXT:     entry:
            // CompOperator-NEXT:     %cmptmp = fcmp olt double %0, 1.000000e+01
            // CompOperator-NEXT:     %1 = sitofp i1 %cmptmp to double
            // CompOperator-NEXT:     ret double %1
            // CompOperator-NEXT: }
            buildContext.dump()
        })
    }

    // 7-3ex
    func testGenerateCompOperatorExLE() {
        let variableNode = VariableNode(identifier: "a")
        let numberNode = NumberNode(value: 10)
        let body = BinaryExpressionNode(.lessEqual, lhs: variableNode, rhs: numberNode)
        let node = FunctionNode(name: "main",
                                arguments: [.init(label: nil, variableName: "a")],
                                returnType: .double,
                                body: body)

        let buildContext = BuildContext()
        build([node], context: buildContext)
        XCTAssertTrue(fileCheckOutput(of: .stderr, withPrefixes: ["CompOperatorLE"]) {
            // CompOperatorLE: ; ModuleID = 'main'
            // CompOperatorLE-NEXT: source_filename = "main"

            // CompOperatorLE: define double @main(double) {
            // CompOperatorLE-NEXT:     entry:
            // CompOperatorLE-NEXT:     %cmptmp = fcmp ole double %0, 1.000000e+01
            // CompOperatorLE-NEXT:     %1 = sitofp i1 %cmptmp to double
            // CompOperatorLE-NEXT:     ret double %1
            // CompOperatorLE-NEXT: }
            buildContext.dump()
        })
    }
    func testGenerateCompOperatorExGT() {
        let variableNode = VariableNode(identifier: "a")
        let numberNode = NumberNode(value: 10)
        let body = BinaryExpressionNode(.greaterThan, lhs: variableNode, rhs: numberNode)
        let node = FunctionNode(name: "main",
                                arguments: [.init(label: nil, variableName: "a")],
                                returnType: .double,
                                body: body)

        let buildContext = BuildContext()
        build([node], context: buildContext)
        XCTAssertTrue(fileCheckOutput(of: .stderr, withPrefixes: ["CompOperatorGT"]) {
            // CompOperatorGT: ; ModuleID = 'main'
            // CompOperatorGT-NEXT: source_filename = "main"

            // CompOperatorGT: define double @main(double) {
            // CompOperatorGT-NEXT:     entry:
            // CompOperatorGT-NEXT:     %cmptmp = fcmp ogt double %0, 1.000000e+01
            // CompOperatorGT-NEXT:     %1 = sitofp i1 %cmptmp to double
            // CompOperatorGT-NEXT:     ret double %1
            // CompOperatorGT-NEXT: }
            buildContext.dump()
        })
    }
    func testGenerateCompOperatorExGE() {
        let variableNode = VariableNode(identifier: "a")
        let numberNode = NumberNode(value: 10)
        let body = BinaryExpressionNode(.greaterEqual, lhs: variableNode, rhs: numberNode)
        let node = FunctionNode(name: "main",
                                arguments: [.init(label: nil, variableName: "a")],
                                returnType: .double,
                                body: body)

        let buildContext = BuildContext()
        build([node], context: buildContext)
        XCTAssertTrue(fileCheckOutput(of: .stderr, withPrefixes: ["CompOperatorGE"]) {
            // CompOperatorGE: ; ModuleID = 'main'
            // CompOperatorGE-NEXT: source_filename = "main"

            // CompOperatorGE: define double @main(double) {
            // CompOperatorGE-NEXT:     entry:
            // CompOperatorGE-NEXT:     %cmptmp = fcmp oge double %0, 1.000000e+01
            // CompOperatorGE-NEXT:     %1 = sitofp i1 %cmptmp to double
            // CompOperatorGE-NEXT:     ret double %1
            // CompOperatorGE-NEXT: }
            buildContext.dump()
        })
    }
    func testGenerateCompOperatorExEq() {
        let variableNode = VariableNode(identifier: "a")
        let numberNode = NumberNode(value: 10)
        let body = BinaryExpressionNode(.equal, lhs: variableNode, rhs: numberNode)
        let node = FunctionNode(name: "main",
                                arguments: [.init(label: nil, variableName: "a")],
                                returnType: .double,
                                body: body)

        let buildContext = BuildContext()
        build([node], context: buildContext)
        XCTAssertTrue(fileCheckOutput(of: .stderr, withPrefixes: ["CompOperatorEq"]) {
            // CompOperatorEq: ; ModuleID = 'main'
            // CompOperatorEq-NEXT: source_filename = "main"

            // CompOperatorEq: define double @main(double) {
            // CompOperatorEq-NEXT:     entry:
            // CompOperatorEq-NEXT:     %cmptmp = fcmp oeq double %0, 1.000000e+01
            // CompOperatorEq-NEXT:     %1 = sitofp i1 %cmptmp to double
            // CompOperatorEq-NEXT:     ret double %1
            // CompOperatorEq-NEXT: }
            buildContext.dump()
        })
    }
    func testGenerateCompOperatorExNe() {
        let variableNode = VariableNode(identifier: "a")
        let numberNode = NumberNode(value: 10)
        let body = BinaryExpressionNode(.notEqual, lhs: variableNode, rhs: numberNode)
        let node = FunctionNode(name: "main",
                                arguments: [.init(label: nil, variableName: "a")],
                                returnType: .double,
                                body: body)

        let buildContext = BuildContext()
        build([node], context: buildContext)
        XCTAssertTrue(fileCheckOutput(of: .stderr, withPrefixes: ["CompOperatorNe"]) {
            // CompOperatorNe: ; ModuleID = 'main'
            // CompOperatorNe-NEXT: source_filename = "main"

            // CompOperatorNe: define double @main(double) {
            // CompOperatorNe-NEXT:     entry:
            // CompOperatorNe-NEXT:     %cmptmp = fcmp one double %0, 1.000000e+01
            // CompOperatorNe-NEXT:     %1 = sitofp i1 %cmptmp to double
            // CompOperatorNe-NEXT:     ret double %1
            // CompOperatorNe-NEXT: }
            buildContext.dump()
        })
    }

    // 7-4
    func testGenerateIfElse() {
        let variableNode = VariableNode(identifier: "a")
        let numberNode = NumberNode(value: 10)
        let condition = BinaryExpressionNode(.lessThan, lhs: variableNode, rhs: numberNode)
        let elseBlock = NumberNode(value: 42)
        let thenBlock = NumberNode(value: 142)

        let ifElseNode = IfElseNode(condition: condition, then: thenBlock, else: elseBlock)

        let globalFunctionNode = FunctionNode(name: "main",
                                              arguments: [.init(label: nil, variableName: "a")],
                                              returnType: .double,
                                              body: ifElseNode)
        let buildContext = BuildContext()
        build([globalFunctionNode], context: buildContext)
        XCTAssertTrue(fileCheckOutput(of: .stderr, withPrefixes: ["IfElse"]) {
            // IfElse: ; ModuleID = 'main'
            // IfElse-NEXT: source_filename = "main"
            // IfElse: define double @main(double) {
            // IfElse-NEXT:     entry:
            // IfElse-NEXT:     %cmptmp = fcmp olt double %0, 1.000000e+01
            // IfElse-NEXT:     %1 = sitofp i1 %cmptmp to double
            // IfElse-NEXT:     %ifcond = fcmp one double %1, 0.000000e+00
            // IfElse-NEXT:     br i1 %ifcond, label %then, label %else
            //
            // IfElse:     then:                                             ; preds = %entry
            // IfElse-NEXT:     br label %merge
            //
            // IfElse:     else:                                             ; preds = %entry
            // IfElse-NEXT:     br label %merge
            //
            // IfElse:     merge:                                            ; preds = %else, %then
            // IfElse-NEXT:     %phi = phi double [ 1.420000e+02, %then ], [ 4.200000e+01, %else ]
            // IfElse-NEXT:     ret double %phi
            // IfElse-NEXT: }
            buildContext.dump()
        })
    }

    // 7-4ex
    func testGenerateIf() {
        let variableNode = VariableNode(identifier: "a")
        let numberNode = NumberNode(value: 10)
        let condition = BinaryExpressionNode(.lessThan, lhs: variableNode, rhs: numberNode)
        let thenBlock = NumberNode(value: 142)

        let ifElseNode = IfElseNode(condition: condition, then: thenBlock, else: nil)

        let globalFunctionNode = FunctionNode(name: "main",
                                              arguments: [.init(label: nil, variableName: "a")],
                                              returnType: .double,
                                              body: ifElseNode)
        let buildContext = BuildContext()
        build([globalFunctionNode], context: buildContext)
        XCTAssertTrue(fileCheckOutput(of: .stderr, withPrefixes: ["If"]) {
            // If: ; ModuleID = 'main'
            // If-NEXT: source_filename = "main"
            // If: define double @main(double) {
            // If-NEXT:     entry:
            // If-NEXT:     %cmptmp = fcmp olt double %0, 1.000000e+01
            // If-NEXT:     %1 = sitofp i1 %cmptmp to double
            // If-NEXT:     %ifcond = fcmp one double %1, 0.000000e+00
            // If-NEXT:     br i1 %ifcond, label %then, label %else
            //
            // If:     then:                                             ; preds = %entry
            // If-NEXT:     br label %merge
            //
            // If:     else:                                             ; preds = %entry
            // If-NEXT:     br label %merge
            //
            // If:     merge:                                            ; preds = %else, %then
            // If-NEXT:     %phi = phi double [ 1.420000e+02, %then ], [ 0.000000e+00, %else ]
            // If-NEXT:     ret double %phi
            // If-NEXT: }
            buildContext.dump()
        })
    }
}
