import Foundation
import LLVM

@discardableResult
func generateIRValue(from node: Node, with context: BuildContext) -> IRValue {
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
    case let voidNode as VoidNode:
        return Generator<VoidNode>(node: voidNode).generate(with: context)
    case let letNode as LetNode:
        return Generator<LetNode>(node: letNode).generate(with: context)
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
        let left = generateIRValue(from: node.lhs, with: context)
        let right = generateIRValue(from: node.rhs, with: context)

        switch node.operator {
            case .addition:
                return context.builder.buildAdd(left, right, name: "addtmp")
            case .subtraction:
                return context.builder.buildSub(left, right, name: "subtmp")
            case .multication:
                return context.builder.buildMul(left, right, name: "multmp")
            case .division:
                return context.builder.buildDiv(left, right, name: "divtmp")
            case .modulo:
                return context.builder.buildRem(left, right, name: "modtmp")
            case .lessThan:
                let cmptmp = context.builder.buildFCmp(left, right, .orderedLessThan, name: "cmptmp")
                return context.builder.buildIntToFP(cmptmp, type: FloatType.double, signed: true)
            case .lessEqual:
                let cmptmp = context.builder.buildFCmp(left, right, .orderedLessThanOrEqual, name: "cmptmp")
                return context.builder.buildIntToFP(cmptmp, type: FloatType.double, signed: true)
            case .greaterThan:
                let cmptmp = context.builder.buildFCmp(left, right, .orderedGreaterThan, name: "cmptmp")
                return context.builder.buildIntToFP(cmptmp, type: FloatType.double, signed: true)
            case .greaterEqual:
                let cmptmp = context.builder.buildFCmp(left, right, .orderedGreaterThanOrEqual, name: "cmptmp")
                return context.builder.buildIntToFP(cmptmp, type: FloatType.double, signed: true)
            case .equal:
                let cmptmp = context.builder.buildFCmp(left, right, .orderedEqual, name: "cmptmp")
                return context.builder.buildIntToFP(cmptmp, type: FloatType.double, signed: true)
            case .notEqual:
                let cmptmp = context.builder.buildFCmp(left, right, .orderedNotEqual, name: "cmptmp")
                return context.builder.buildIntToFP(cmptmp, type: FloatType.double, signed: true)
        }
    }
}

extension Generator where NodeType == CallExpressionNode {
    func generate(with context: BuildContext) -> IRValue {
        let arguments: [IRValue] = node.arguments.map {
            generateIRValue(from: $0.value, with: context)
        }

        let callee = context.module.function(named: node.callee) ?? {
            let argumentTypes: [IRType] = arguments.map { $0.type }
            let returnType = FloatType.double // TODO: always double
            let isVarArg = false // TODO: always false
            let functionType = FunctionType(argTypes: argumentTypes, returnType: returnType, isVarArg: isVarArg)

            return context.builder.addFunction(node.callee, type: functionType)
        }()

        return context.builder.buildCall(callee, args: arguments, name: "calltmp")
    }
}

extension Generator where NodeType == ReturnNode {
    func generate(with context: BuildContext) -> IRValue {
        if let body = node.body {
            let returnValue = generateIRValue(from: body, with: context)
            return returnValue
        } else {
            return VoidType().null()
        }
    }
}

extension Generator where NodeType == VoidNode {
    func generate(with context: BuildContext) -> IRValue {
        return VoidType().null()
    }
}

extension Generator where NodeType == IfElseNode {
    func generate(with context: BuildContext) -> IRValue {
        let condition = generateIRValue(from: node.condition, with: context)
        let condBool = context.builder.buildFCmp(condition, FloatType.double.constant(0), .orderedNotEqual, name: "ifcond")

        let function = context.builder.insertBlock!.parent!
        let thenBasicBlock = function.appendBasicBlock(named: "then")
        let elseBasicBlock = function.appendBasicBlock(named: "else")
        let mergeBasicBlock = function.appendBasicBlock(named: "merge")

        context.builder.buildCondBr(condition: condBool, then: thenBasicBlock, else: elseBasicBlock)

        context.builder.positionAtEnd(of: thenBasicBlock)
        let thenValue = generateIRValue(from: node.then, with: context)
        context.builder.buildBr(mergeBasicBlock)

        context.builder.positionAtEnd(of: elseBasicBlock)
        let elseValue: IRValue
        if let `else` = node.else {
            elseValue = generateIRValue(from: `else`, with: context)
        } else {
            elseValue = FloatType.double.constant(0)
        }
        context.builder.buildBr(mergeBasicBlock)

        context.builder.positionAtEnd(of: mergeBasicBlock)
        let phi = context.builder.buildPhi(FloatType.double, name: "phi")
        phi.addIncoming([(thenValue, thenBasicBlock), (elseValue, elseBasicBlock)])

        return phi
    }
}

extension Generator where NodeType == FunctionNode {
    func generate(with context: BuildContext) -> IRValue {
        let argumentTypes: [IRType] = node.arguments.map { $0.valueType.toIRType() }
        let returnType = node.returnType.toIRType()
        let functionType = FunctionType(argTypes: argumentTypes, returnType: returnType)

        let function = context.builder.addFunction(node.name, type: functionType)

        let entryBasicBlock = function.appendBasicBlock(named: "entry")
        context.builder.positionAtEnd(of: entryBasicBlock)

        // Register arguments to namedValues
        context.namedValues = node.arguments.enumerated().reduce(into: [:]) { (map, x) in
            map[x.1.variableName] = function.parameters[x.0]
        }

        let functionBody = generateIRValue(from: node.body, with: context)

        context.builder.buildRet(functionBody)
        return functionBody
    }
}

extension Generator where NodeType == LetNode {
    func generate(with context: BuildContext) -> IRValue {
        if context.namedValues[node.identifier] != nil {
            fatalError("variable \(node.identifier) is already defined")
        }

        let initial = generateIRValue(from: node.initializer, with: context)

        context.namedValues[node.identifier] = initial

        let body = generateIRValue(from: node.body, with: context)

        return body
    }
}

extension Type {
    func toIRType() -> IRType {
        switch self {
        case .double:
            return FloatType.double
        case .int:
            return IntType.int64
        case .void:
            return VoidType()
        }
    }
}
