import Foundation
import LLVM

@discardableResult
func generate(from node: Node, with context: BuildContext) -> IRValue {
    switch node {
    case let numberNode as NumberNode:
        return Generator<NumberNode>(node: numberNode).generate(with: context)
    case let binaryExpressionNode as BinaryExpressionNode:
        return Generator<BinaryExpressionNode>(node: binaryExpressionNode).generate(with: context)
    case let variableNode as VariableNode:
        return Generator<VariableNode>(node: variableNode).generate(with: context)
    case let functionNode as FunctionNode:
        return Generator<FunctionNode>(node: functionNode).generate(with: context)
    case let callExpressionNode as CallExpressionNode:
        return Generator<CallExpressionNode>(node: callExpressionNode).generate(with: context)
    case let ifElseNode as IfElseNode:
        return Generator<IfElseNode>(node: ifElseNode).generate(with: context)
    case let returnNode as ReturnNode:
        return Generator<ReturnNode>(node: returnNode).generate(with: context)
    default:
        fatalError("Unknown node type \(type(of: node))")
    }
}

private protocol GeneratorProtocol {
    associatedtype NodeType: Node
    var node: NodeType { get }
    func generate(with: BuildContext) -> IRValue
    init(node: NodeType)
}

private struct Generator<NodeType: Node>: GeneratorProtocol {
    func generate(with context: BuildContext) -> IRValue {
        fatalError("Not implemented")
    }

    let node: NodeType
    init(node: NodeType) {
        self.node = node
    }
}

// MARK: Practice 6

extension Generator where NodeType == NumberNode {
    func generate(with context: BuildContext) -> IRValue {
        return FloatType.double.constant(node.value)
    }
}

extension Generator where NodeType == VariableNode {
   func generate(with context: BuildContext) -> IRValue {
       guard let value = context.namedValues[node.identifier] else {
           fatalError("Undefined variable \(node.identifier)")
       }

       return value
   }
}

extension Generator where NodeType == BinaryExpressionNode {
    func generate(with context: BuildContext) -> IRValue {
        let left = MinSwiftKit.generate(from: node.lhs, with: context)
        let right = MinSwiftKit.generate(from: node.rhs, with: context)

        switch node.operator {
            case .addition:
                return context.builder.buildAdd(left, right, name: "addtmp")
            case .subtraction:
                return context.builder.buildSub(left, right, name: "subtmp")
            case .multication:
                return context.builder.buildMul(left, right, name: "multmp")
            case .division:
                return context.builder.buildDiv(left, right, name: "divtmp")
            case .lessThan:
               fatalError("Not implemented")
        }
    }
}

extension Generator where NodeType == CallExpressionNode {
    func generate(with context: BuildContext) -> IRValue {
        let arguments: [IRValue] = node.arguments.map {
            MinSwiftKit.generate(from: $0.value, with: context)
        }

        guard let callee = context.module.function(named: node.callee) else {
            fatalError("function \(node.callee) not found")
        }

        return context.builder.buildCall(callee, args: arguments, name: "calltmp")
    }
}

// ...

extension Generator where NodeType == ReturnNode {
    func generate(with context: BuildContext) -> IRValue {
        if let body = node.body {
            let returnValue = MinSwiftKit.generate(from: body, with: context)
            return returnValue
        } else {
            return VoidType().null()
        }
    }
}

extension Generator where NodeType == FunctionNode {
    func generate(with context: BuildContext) -> IRValue {
        let argumentTypes: [IRType] = node.arguments.map { _ in FloatType.double }
        let returnType: IRType = FloatType.double
        let functionType = FunctionType(argTypes: argumentTypes, returnType: returnType)

        let function = context.builder.addFunction(node.name, type: functionType)

        let entryBasicBlock = function.appendBasicBlock(named: "entry")
        context.builder.positionAtEnd(of: entryBasicBlock)

        // Register arguments to namedValues
        context.namedValues = node.arguments.enumerated().reduce(into: [:]) { (map, x) in
            map[x.1.variableName] = function.parameters[x.0]
        }

        let functionBody = MinSwiftKit.generate(from: node.body, with: context)

        context.builder.buildRet(functionBody)
        return functionBody
    }
}
