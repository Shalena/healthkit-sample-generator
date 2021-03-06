import Foundation

public typealias MatcherBlock = (_ actualExpression: Expression<NSObject>, _ failureMessage: FailureMessage) -> Bool
public typealias FullMatcherBlock = (_ actualExpression: Expression<NSObject>, _ failureMessage: FailureMessage, _ shouldNotMatch: Bool) -> Bool
open class NMBObjCMatcher : NSObject, NMBMatcher {
    let _match: MatcherBlock
    let _doesNotMatch: MatcherBlock
    let canMatchNil: Bool

    public init(canMatchNil: Bool, matcher: @escaping MatcherBlock, notMatcher: @escaping MatcherBlock) {
        self.canMatchNil = canMatchNil
        self._match = matcher
        self._doesNotMatch = notMatcher
    }

    public convenience init(matcher: MatcherBlock) {
        self.init(canMatchNil: true, matcher: matcher)
    }

    public convenience init(canMatchNil: Bool, matcher: @escaping MatcherBlock) {
        self.init(canMatchNil: canMatchNil, matcher: matcher, notMatcher: ({ actualExpression, failureMessage in
            return !matcher(actualExpression, failureMessage)
        }))
    }

    public convenience init(matcher: FullMatcherBlock) {
        self.init(canMatchNil: true, matcher: matcher)
    }

    public convenience init(canMatchNil: Bool, matcher: @escaping FullMatcherBlock) {
        self.init(canMatchNil: canMatchNil, matcher: ({ actualExpression, failureMessage in
            return matcher(actualExpression, failureMessage, false)
        }), notMatcher: ({ actualExpression, failureMessage in
            return matcher(actualExpression, failureMessage, true)
        }))
    }

    fileprivate func canMatch(_ actualExpression: Expression<NSObject>, failureMessage: FailureMessage) -> Bool {
        do {
            if !canMatchNil {
                if try actualExpression.evaluate() == nil {
                    failureMessage.postfixActual = " (use beNil() to match nils)"
                    return false
                }
            }
        } catch let error {
            failureMessage.actualValue = "an unexpected error thrown: \(error)"
            return false
        }
        return true
    }

    open func matches(_ actualBlock: () -> NSObject!, failureMessage: FailureMessage, location: SourceLocation) -> Bool {
        let expr = Expression(expression: actualBlock, location: location)
        let result = _match(
            expr,
            failureMessage)
        if self.canMatch(Expression(expression: actualBlock, location: location), failureMessage: failureMessage) {
            return result
        } else {
            return false
        }
    }

    open func doesNotMatch(_ actualBlock: () -> NSObject!, failureMessage: FailureMessage, location: SourceLocation) -> Bool {
        let expr = Expression(expression: actualBlock, location: location)
        let result = _doesNotMatch(
            expr,
            failureMessage)
        if self.canMatch(Expression(expression: actualBlock, location: location), failureMessage: failureMessage) {
            return result
        } else {
            return false
        }
    }
}

