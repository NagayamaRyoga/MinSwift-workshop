import Foundation
import SwiftSyntax

private extension BinaryExpressionNode.Operator {
    var precedence: Int {
        switch self {
        case .addition, .subtraction: return 20
        case .multication, .division: return 40
        case .lessThan:
            fatalError("Not Implemented")
        }
    }
}

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
                return Double(token.text)

            default:
                return nil
        }
    }

    func parseNumber() -> Node? {
        guard let value = extractNumberLiteral(from: currentToken) else {
            return nil
        }
        read() // eat literal
        return NumberNode(value: value)
    }

    func parseIdentifierExpression() -> Node? {
        guard case .identifier(let text) = currentToken!.tokenKind else {
            return nil
        }
        read() // eat identifier
        return VariableNode(identifier: text)
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
            case .spacedBinaryOperator("<"):
                return .lessThan
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

        guard case .identifier("Double") = currentToken!.tokenKind else {
            fatalError("Double is expected but received \(currentToken.tokenKind)")
        }
        read() // eat Double

        return FunctionNode.Argument(label: isWildcard ? nil : (label ?? name), variableName: name)
    }

    func parseFunctionDefinition() -> Node {
        fatalError("Not Implemented")
    }

    // MARK: Practice 7

    func parseIfElse() -> Node {
        fatalError("Not Implemented")
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
        case .integerLiteral, .floatingLiteral:
            return parseNumber()
        case .leftParen:
            return parseParen()
        case .funcKeyword:
            return parseFunctionDefinition()
        case .returnKeyword:
            return parseReturn()
        case .ifKeyword:
            return parseIfElse()
        case .eof:
            return nil
        default:
            fatalError("Unexpected token \(currentToken.tokenKind) \(currentToken.text)")
        }
        return nil
    }

    func parseExpression() -> Node? {
        guard let lhs = parsePrimary() else {
            return nil
        }
        return parseBinaryOperatorRHS(expressionPrecedence: 0, lhs: lhs)
    }

    private func parseReturn() -> Node? {
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
}
