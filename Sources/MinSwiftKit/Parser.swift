import Foundation
import SwiftSyntax

class Parser: SyntaxVisitor {
    private(set) var tokens: [TokenSyntax] = []
    private var index = 0
    private(set) var currentToken: TokenSyntax!

    // MARK: Practice 1

    override func visit(_ token: TokenSyntax) {
        print("Parsing \(token.tokenKind)")

        tokens.append(token)
    }

    @discardableResult
    func read() -> TokenSyntax {
        currentToken = tokens[index]
        index = min(index + 1, tokens.count - 1)
        return currentToken
    }

    func peek(_ n: Int = 0) -> TokenSyntax {
        return tokens[min(index + n, tokens.count - 1)]
    }

    // MARK: Practice 2

    private func extractNumberLiteral(from token: TokenSyntax) -> Double? {
        switch token.tokenKind {
            case .integerLiteral, .floatingLiteral:
                return Double(token.text.replacingOccurrences(of: "_", with: ""))

            default:
                return nil
        }
    }

    func parseNumber() -> Node {
        let negative: Bool
        if case .prefixOperator("-") = currentToken!.tokenKind {
            read() // eat -

            negative = true
        } else {
            negative = false
        }

        guard let value = extractNumberLiteral(from: currentToken) else {
            fatalError("any number is expected")
        }
        read() // eat literal
        return NumberNode(value: negative ? -value : value)
    }

    func parseCallExpressionArgument() -> CallExpressionNode.Argument {
        let label: String?
        if case .colon = peek().tokenKind {
            guard case .identifier(let text) = currentToken!.tokenKind else {
                fatalError("identifier is expected but received \(currentToken.tokenKind)")
            }
            read() // eat identifier
            read() // eat colon

            label = text
        } else {
            label = nil
        }

        guard let value = parseExpression() else {
            fatalError("expression is expected")
        }

        return CallExpressionNode.Argument(label: label, value: value)
    }

    func parseIdentifierExpression() -> Node {
        guard case .identifier(let name) = currentToken!.tokenKind else {
            fatalError("identifier is expected but received \(currentToken.tokenKind)")
        }
        read() // eat identifier

        guard case .leftParen = currentToken!.tokenKind else {
            return VariableNode(identifier: name)
        }
        read() // eat (

        var arguments: [CallExpressionNode.Argument] = []

        if case .rightParen = currentToken!.tokenKind {} else {
            while true {
                if arguments.count > 0 {
                    guard case .comma = currentToken!.tokenKind else {
                        break
                    }
                    read() // eat ,
                }

                arguments.append(parseCallExpressionArgument())
            }
        }

        guard case .rightParen = currentToken!.tokenKind else {
            fatalError("rightParen is expected but received \(currentToken.tokenKind)")
        }
        read() // eat )

        return CallExpressionNode(callee: name, arguments: arguments)
    }

    // MARK: Practice 3

    func extractBinaryOperator(from token: TokenSyntax) -> BinaryExpressionNode.Operator? {
        switch token.tokenKind {
            case .spacedBinaryOperator("+"):
                return .addition
            case .spacedBinaryOperator("-"):
                return .subtraction
            case .spacedBinaryOperator("*"):
                return .multication
            case .spacedBinaryOperator("/"):
                return .division
            case .spacedBinaryOperator("%"):
                return .modulo
            case .spacedBinaryOperator("<"):
                return .lessThan
            case .spacedBinaryOperator("<="):
                return .lessEqual
            case .spacedBinaryOperator(">"):
                return .greaterThan
            case .spacedBinaryOperator(">="):
                return .greaterEqual
            case .spacedBinaryOperator("=="):
                return .equal
            case .spacedBinaryOperator("!="):
                return .notEqual
            default:
                return nil
        }
    }

    private func parseBinaryOperatorRHS(expressionPrecedence: Int, lhs: Node?) -> Node? {
        var currentLHS: Node? = lhs
        while true {
            let binaryOperator = extractBinaryOperator(from: currentToken!)
            let operatorPrecedence = binaryOperator?.precedence ?? -1

            // Compare between operatorPrecedence and expressionPrecedence
            if operatorPrecedence < expressionPrecedence {
                return currentLHS
            }

            read() // eat binary operator
            var rhs = parsePrimary()
            if rhs == nil {
                return nil
            }

            // If binOperator binds less tightly with RHS than the operator after RHS, let
            // the pending operator take RHS as its LHS.
            let nextPrecedence = extractBinaryOperator(from: currentToken!)?.precedence ?? -1
            if nextPrecedence > operatorPrecedence {
                // Search next RHS from currentRHS
                // next precedence will be `operatorPrecedence + 1`
                rhs = parseBinaryOperatorRHS(expressionPrecedence: operatorPrecedence + 1, lhs: rhs)
                if rhs == nil {
                    return nil
                }
            }

            guard let nonOptionalRHS = rhs else {
                fatalError("rhs must be nonnull")
            }

            // Update current LHS
            currentLHS = BinaryExpressionNode(binaryOperator!, lhs: currentLHS!, rhs: nonOptionalRHS)
        }
    }

    // MARK: Practice 4

    func parseFunctionDefinitionArgument() -> FunctionNode.Argument {
        let isWildcard: Bool
        let label: String?
        if case .wildcardKeyword = currentToken!.tokenKind {
            read() // eat _

            isWildcard = true
            label = nil
        } else if case .identifier = peek().tokenKind {
            guard case .identifier(let text) = currentToken!.tokenKind else {
                fatalError("identifier is expected but received \(currentToken.tokenKind)")
            }
            read() // eat identifier

            isWildcard = false
            label = text
        } else {
            isWildcard = false
            label = nil
        }

        guard case .identifier(let name) = currentToken!.tokenKind else {
            fatalError("identifier is expected but received \(currentToken.tokenKind)")
        }
        read() // eat identifier

        guard case .colon = currentToken!.tokenKind else {
            fatalError("colon is expected but received \(currentToken.tokenKind)")
        }
        read() // eat :

        let valueType = parseType()

        return FunctionNode.Argument(label: isWildcard ? nil : (label ?? name),
                                     variableName: name,
                                     valueType: valueType)
    }

    func parseFunctionDefinition() -> Node {
        guard case .funcKeyword = currentToken!.tokenKind else {
            fatalError("funcKeyword is expected but received \(currentToken.tokenKind)")
        }
        read() // eat func

        guard case .identifier(let name) = currentToken!.tokenKind else {
            fatalError("identifier is expected but received \(currentToken.tokenKind)")
        }
        read() // eat identifier

        guard case .leftParen = currentToken!.tokenKind else {
            fatalError("leftParen is expected but received \(currentToken.tokenKind)")
        }
        read() // eat (

        var arguments: [FunctionNode.Argument] = []

        if case .rightParen = currentToken!.tokenKind {} else {
            while true {
                if arguments.count > 0 {
                    guard case .comma = currentToken!.tokenKind else {
                        break
                    }
                    read() // eat ,
                }

                arguments.append(parseFunctionDefinitionArgument())
            }
        }

        guard case .rightParen = currentToken!.tokenKind else {
            fatalError("rightParen is expected but received \(currentToken.tokenKind)")
        }
        read() // eat )

        let returnType: Type
        if case .arrow = currentToken!.tokenKind {
            read() // eat ->
            returnType = parseType()
        } else {
            returnType = Type.void
        }

        guard case .leftBrace = currentToken!.tokenKind else {
            fatalError("leftBrace is expected but received \(currentToken.tokenKind)")
        }
        read() // eat {

        guard let body = parseExpression() else {
            fatalError("expression is expected")
        }

        guard case .rightBrace = currentToken!.tokenKind else {
            fatalError("rightBrace is expected but received \(currentToken.tokenKind)")
        }
        read() // eat }

        return FunctionNode(name: name, arguments: arguments, returnType: returnType, body: body)
    }

    // MARK: Practice 7

    func parseIfElse() -> Node {
        guard case .ifKeyword = currentToken!.tokenKind else {
            fatalError("ifKeyword is expected but received \(currentToken.tokenKind)")
        }
        read() // eat if

        guard let condition = parseExpression() else {
            fatalError("expression is expected")
        }

        guard case .leftBrace = currentToken!.tokenKind else {
            fatalError("leftBrace is expected but received \(currentToken.tokenKind)")
        }
        read() // eat {

        guard let then = parseExpression() else {
            fatalError("expression is expected")
        }

        guard case .rightBrace = currentToken!.tokenKind else {
            fatalError("rightBrace is expected but received \(currentToken.tokenKind)")
        }
        read() // eat }

        guard case .elseKeyword = currentToken!.tokenKind else {
            return IfElseNode(condition: condition, then: then, else: nil)
        }
        read() // eat else

        guard case .leftBrace = currentToken!.tokenKind else {
            fatalError("leftBrace is expected but received \(currentToken.tokenKind)")
        }
        read() // eat {

        guard let `else` = parseExpression() else {
            fatalError("expression is expected")
        }

        guard case .rightBrace = currentToken!.tokenKind else {
            fatalError("rightBrace is expected but received \(currentToken.tokenKind)")
        }
        read() // eat }

        return IfElseNode(condition: condition, then: then, else: `else`)
    }

    // PROBABLY WORKS WELL, TRUST ME

    func parse() -> [Node] {
        var nodes: [Node] = []
        read()
        while true {
            switch currentToken.tokenKind {
            case .eof:
                return nodes
            case .funcKeyword:
                let node = parseFunctionDefinition()
                nodes.append(node)
            default:
                if let node = parseTopLevelExpression() {
                    nodes.append(node)
                    break
                } else {
                    read()
                }
            }
        }
        return nodes
    }

    private func parsePrimary() -> Node? {
        switch currentToken.tokenKind {
        case .identifier:
            return parseIdentifierExpression()
        case .integerLiteral, .floatingLiteral, .prefixOperator("-"):
            return parseNumber()
        case .leftParen:
            return parseParen()
        case .funcKeyword:
            return parseFunctionDefinition()
        case .returnKeyword:
            return parseReturn()
        case .ifKeyword:
            return parseIfElse()
        default:
            return nil
        }
    }

    func parseExpression() -> Node? {
        guard let lhs = parsePrimary() else {
            return nil
        }
        return parseBinaryOperatorRHS(expressionPrecedence: 0, lhs: lhs)
    }

    private func parseReturn() -> Node {
        guard case .returnKeyword = currentToken.tokenKind else {
            fatalError("returnKeyword is expected but received \(currentToken.tokenKind)")
        }
        read() // eat return
        if let expression = parseExpression() {
            return ReturnNode(body: expression)
        } else {
            // return nothing
            return ReturnNode(body: nil)
        }
    }

    private func parseParen() -> Node? {
        read() // eat (
        guard let v = parseExpression() else {
            return nil
        }

        guard case .rightParen = currentToken.tokenKind else {
                fatalError("expected ')'")
        }
        read() // eat )

        return v
    }

    private func parseTopLevelExpression() -> Node? {
        if let expression = parseExpression() {
            // we treat top level expressions as anonymous functions
            let anonymousPrototype = FunctionNode(name: "main", arguments: [], returnType: .int, body: expression)
            return anonymousPrototype
        }
        return nil
    }

    // MARK: advanced
    private func parseType() -> Type {
        switch currentToken!.tokenKind {
            case .identifier("Double"):
                read() // eat Double
                return Type.double
            case .identifier("Int"):
                read() // eat Int
                return Type.int
            case .identifier("Void"):
                read() // eat Void
                return Type.void
            default:
                fatalError("type name is expected but received \(currentToken.tokenKind)")
        }
    }
}

private extension BinaryExpressionNode.Operator {
    var precedence: Int {
        switch self {
        case .addition, .subtraction: return 20
        case .multication, .division, .modulo: return 40
        case .lessThan, .lessEqual, .greaterThan, .greaterEqual: return 11
        case .equal, .notEqual: return 10
        }
    }
}
