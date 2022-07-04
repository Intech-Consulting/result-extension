import Foundation

// MARK: - Result Protocol

public protocol ResultProtocol {
    associatedtype Success
    associatedtype Failure: Error

    /// Returns the associated value if the result is a success, `nil` otherwise.
    var value: Success? { get }

    /// Returns the associated error value if the result is a failure, `nil` otherwise.
    var error: Failure? { get }

    /// Get Result value
    var result: Result<Success, Failure> { get }
}

// MARK: - AnyFailure

/// A type-erased error which wraps an arbitrary error instance. This should be
/// useful for generic contexts.
public struct AnyFailure: Swift.Error, Sendable {
    /// The underlying error.
    public let error: Swift.Error

    public init(_ error: Swift.Error) {
        if let anyError = error as? AnyFailure {
            self = anyError
        } else {
            self.error = error
        }
    }
}

// MARK: - AnyFailure - ErrorConvertible

extension AnyFailure: ErrorConvertible {
    public static func error(from error: Error) -> AnyFailure {
        return AnyFailure(error)
    }
}

// MARK: - AnyFailure - CustomStringConvertible

extension AnyFailure: CustomStringConvertible {
    /// A textual representation of this instance.
    public var description: String {
        return String(describing: error)
    }
}

// MARK: - AnyFailure - LocalizedError

extension AnyFailure: LocalizedError {
    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        return error.localizedDescription
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? {
        return (error as? LocalizedError)?.failureReason
    }

    /// A localized message providing "help" text if the user requests help.
    public var helpAnchor: String? {
        return (error as? LocalizedError)?.helpAnchor
    }

    /// A localized message describing how one might recover from the failure.
    public var recoverySuggestion: String? {
        return (error as? LocalizedError)?.recoverySuggestion
    }
}

// MARK: - Result Extension - ResultProtocol

extension Result: ResultProtocol where Failure: Error {
    /// Get Result value
    public var result: Result<Success, Failure> {
        return self
    }

    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    public var isFailure: Bool {
        switch self {
        case .failure:
            return true
        case .success:
            return false
        }
    }
}

// MARK: - Result Extension - Initializer

extension Result where Failure: Error {
    /// Constructs a success wrapping a `value`.
    public init(value: Success) {
        self = .success(value)
    }

    /// Constructs a failure wrapping an `error`.
    public init(error: Failure) {
        self = .failure(error)
    }

    /// Returns the value if self represents a success, `nil` otherwise.
    public var value: Success? {
        switch self {
        case let .success(value):
            return value
        default:
            return nil
        }
    }

    /// Returns the error if self represents a failure, `nil` otherwise.
    public var error: Failure? {
        switch self {
        case let .failure(error):
            return error
        default:
            return nil
        }
    }

    /// Constructs a result from an `Optional`, failing with `Error` if `nil`.
    public init(_ value: Success?, failWith: @autoclosure () -> Failure) {
        self = value.map(Result.success) ?? .failure(failWith())
    }

    /// Constructs a result from a function that uses `throw`, failing with `Error` if throws.
    public init(_ f: @autoclosure () throws -> Success) {
        self.init(catching: f)
    }

    /// The same as `init(attempt:)` aiming for the compatibility with the Swift 5's `Result` in the standard library.
    public init(catching body: () throws -> Success) {
        do {
            self = .success(try body())
        } catch var error {
            if Failure.self == AnyFailure.self {
                error = AnyFailure(error)
            }
            self = .failure(error as! Failure)
        }
    }
}

// MARK: - Result Extension - Transformer

extension Result where Failure: Error {
    /// Returns the result of applying `transform` with optional value to `Success`es’ values,
    /// or re-wrapping `Failure`’s errors.
    @inlinable
    public func compactMap<U>(_ transform: (Success?) -> U) -> Result<U, Failure> {
        switch self {
        case let .success(value): return .success(transform(value))
        case let .failure(error): return .failure(error)
        }
    }

    /// Returns a new Result by mapping `Failure`'s with optional value to `transform`,
    /// or re-wrapping `Success`’s errors.
    @inlinable
    public func compactMapError<E: Swift.Error>(_ transform: (Failure?) -> E) -> Result<Success, E> {
        switch self {
        case let .success(value): return .success(value)
        case let .failure(error): return .failure(transform(error))
        }
    }

    /// Returns a new Result by mapping `Success`es’ values using `success`, and by mapping `Failure`'s values using `failure`.
    @inlinable
    public func bimap<U, E>(success: (Success) -> U, failure: (Failure) -> E) -> Result<U, E> {
        switch self {
        case let .success(value): return .success(success(value))
        case let .failure(error): return .failure(failure(error))
        }
    }

    /// Returns a Result with a tuple of the receiver and `other` values if both
    /// are `Success`es, or re-wrapping the error of the earlier `Failure`.
    @inlinable
    public func fanout<U>(_ other: @autoclosure () -> Result<U, Failure>) -> Result<(Success, U), Failure> {
        return self.flatMap { left in other().map { right in (left, right) } }
    }

    /// Case analysis for Result.
    ///
    /// Returns the value produced by applying `ifFailure` to `failure` Results, or `ifSuccess` to `success` Results.
    @inlinable
    public func analysis<Result>(ifSuccess: (Success) -> Result, ifFailure: (Failure) -> Result) -> Result {
        switch self {
        case let .success(value):
            return ifSuccess(value)
        case let .failure(value):
            return ifFailure(value)
        }
    }

    /// Returns the result of applying `transform` to `Success`es’ values, or wrapping thrown errors.
    @inlinable
    public func tryMap<T>(_ transform:(Success) throws -> T)  -> Result<T, Swift.Error> {
        switch self {
        case let .success(success):
            do {
                return .success(try transform(success))
            } catch {
                return .failure(error)
            }
        case let .failure(failure):
            return .failure(failure)
        }
    }
}

// MARK: - Result Extension - Higher-order functions

extension Result {
    /// Returns `self.value` if this result is a .Success, or the given value otherwise. Equivalent with `??`
    @inlinable
    public func recover(_ value: @autoclosure () -> Success) -> Success {
        return self.value ?? value()
    }

    /// Returns this result if it is a .Success, or the given result otherwise. Equivalent with `??`
    @inlinable
    public func recover(with result: @autoclosure () -> Result<Success, Failure>) -> Result<Success, Failure> {
        switch self {
        case .success: return self
        case .failure: return result()
        }
    }
}

// MARK: - Result Extension - Convert to Throws

extension Result {
    /// Return value or catch error
    @inlinable
    public func convertThrow() throws -> Success {
        switch self {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}

// MARK: - ErrorConvertible

/// Protocol used to constrain `tryMap` to `Result`s with compatible `Error`s.
public protocol ErrorConvertible: Swift.Error {
    static func error(from error: Swift.Error) -> Self
}

// MARK: - Result Extension - ErrorConvertible

extension Result where Result.Failure: ErrorConvertible {
    /// Returns the result of applying `transform` to `Success`es’ values, or wrapping thrown errors.
    @inlinable
    public func tryMap<U>(_ transform: (Success) throws -> U) -> Result<U, Failure> {
        return flatMap { value in
            do {
                return .success(try transform(value))
            }
            catch {
                let convertedError = Failure.error(from: error)
                return .failure(convertedError)
            }
        }
    }
}

// MARK: - Result Extension - Operators

extension Result {
    /// Returns the value of `left` if it is a `Success`, or `right` otherwise. Short-circuits.
    public static func ??(left: Result<Success, Failure>, right: @autoclosure () -> Success) -> Success {
        return left.recover(right())
    }

    /// Returns `left` if it is a `Success`es, or `right` otherwise. Short-circuits.
    public static func ??(left: Result<Success, Failure>, right: @autoclosure () -> Result<Success, Failure>) -> Result<Success, Failure> {
        return left.recover(with: right())
    }
}

// MARK: - Result Extension - CustomStringConvertible

extension Result: CustomStringConvertible {
    /// A textual representation of this instance.
    public var description: String {
        switch self {
        case let .success(value): return ".success(\(value))"
        case let .failure(error): return ".failure(\(error))"
        }
    }
}

// MARK: - Result Extension - CustomDebugStringConvertible

extension Result: CustomDebugStringConvertible {
    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        return description
    }
}
