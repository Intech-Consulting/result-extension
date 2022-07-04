import XCTest
@testable import ResultExtension

class ResultExtensionTests: XCTestCase {
    enum TestError: Error {
        case empty
    }

    func testIsSuccess() {
        let result = Result<Int, TestError>(value: 56)

        XCTAssertTrue(result.isSuccess)
    }

    func testIsNotSuccess() {
        let result = Result<Int, TestError>(error: .empty)

        XCTAssertFalse(result.isSuccess)
    }

    func testResultValue() {
        let result = Result<Int, TestError>(value: 56)

        XCTAssertEqual(result.result, result)
    }

    func testValueSuccess() {
        let result = Result<Int, TestError>(value: 56)

        XCTAssertEqual(result.value, 56)
    }

    func testValueSuccessNil() {
        let result = Result<Int, TestError>(error: .empty)

        XCTAssertNil(result.value)
    }

    func testFailureValueNil() {
        let result = Result<Int, TestError>(value: 56)

        XCTAssertNil(result.error)
    }

    func testFailureValue() {
        let result = Result<Int, TestError>(error: .empty)

        XCTAssertEqual(result.error, .empty)
    }

    func testIsNotFailure() {
        let result = Result<Int, TestError>(value: 56)

        XCTAssertFalse(result.isFailure)
    }

    func testIsFailure() {
        let result = Result<Int, TestError>(error: .empty)

        XCTAssertTrue(result.isFailure)
    }

    func testConvertThrowSuccess() {
        let result = Result<Int, TestError>(value: 56)

        XCTAssertNoThrow(try result.convertThrow())
    }

    func testConvertThrowFailure() {
        let result = Result<Int, TestError>(error: .empty)

        XCTAssertThrowsError(try result.convertThrow())
    }

    func testCompactMapSuccess() {
        let result = Result<Int, TestError>(value: 56)

        let newResult = result.compactMap { "\($0 ?? 6)" }

        XCTAssertEqual("56", newResult.value)
    }

    func testCompactMapError() {
        let result = Result<Int, TestError>(error: .empty)

        let newResult = result.compactMap { "\($0 ?? 6)" }

        XCTAssertFalse(newResult.isSuccess)
    }

    private typealias Mapper<Input, Output> = (Input) throws -> Output

    func testTryMapSouldSuccesIfSuccessfullyTransform() throws {
        let alwaysSuccessMapper: Mapper<Int, String> = { _ in "any text" }
        let sut = Result<Int, Error>.success(1)

        let result = try XCTUnwrap(try? sut.tryMap(alwaysSuccessMapper).get())

        XCTAssertEqual(result, "any text")
    }

    func testTryMapSouldFailureWithNewErrorIfFailsTransform() throws {
        let alwaysThrowsMapper: Mapper<Int, String> = { _ in throw AnyError.anyFailure }
        let sut = Result<Int, Error>.success(1)
        let result = sut.tryMap(alwaysThrowsMapper)
        XCTAssertThrowsError(try result.get()) {
            error in
            let anyError = error as? AnyError
            XCTAssertNotNil(anyError)
            XCTAssertEqual(anyError, .anyFailure)
        }
    }

    func testTryMapSouldFailureWithOldErrorIfResultAlreadyAFailure() throws {
        let alwaysThrowsMapper: Mapper<Int, String> = { _ in throw AnyError.anyFailure }
        let sut = Result<Int, Error>.failure(AnyError.originalFailure)
        let result = sut.tryMap(alwaysThrowsMapper)
        XCTAssertThrowsError(try result.get()) {
            error in
            let anyError = error as? AnyError
            XCTAssertNotNil(anyError)
            XCTAssertEqual(anyError, .originalFailure)
        }
    }

    func testTryMapWillExcuteTransformOnlyOnceIfResultisASuccess() throws {
        var captured = [Int]()
        let alwaysSuccessMapper: Mapper<Int, String> = { input in
            captured.append(input)
            return ""
        }
        let sut = Result<Int, Error>.success(0)
        _ = sut.tryMap(alwaysSuccessMapper)
        XCTAssertEqual(captured, [0])
    }

    func testTryMapWillExcuteTransformOnlyOnceIfResultAlreadyAFailure() throws {
        var captured = [Int]()
        let alwaysSuccessMapper: Mapper<Int, String> = { input in
            captured.append(input)
            return ""
        }
        let sut = Result<Int, Error>.failure(AnyError.originalFailure)
        _ = sut.tryMap(alwaysSuccessMapper)
        XCTAssertTrue(captured.isEmpty)
    }

    func testTryMapWillExcuteTransformOnlyOnceIfResultAlreadyASuccessOnTransformIsSuccess() throws {
        var captured = [Int]()
        let alwaysSuccessMapper: Mapper<Int, String> = { input in
            captured.append(input)
            return ""
        }
        let sut = Result<Int, Error>.success(0)
        _ = sut.tryMap(alwaysSuccessMapper)
        XCTAssertEqual(captured, [0])
    }

    func testTryMapWillExcuteTransformOnlyOnceIfResultAlreadyASuccessOnTransformIsThrows() throws {
        var captured = [Int]()
        let alwaysThrowsMapper: Mapper<Int, String> = { input in
            captured.append(input)
            throw AnyError.anyFailure
        }
        let sut = Result<Int, Error>.success(0)
        _ = sut.tryMap(alwaysThrowsMapper)
        XCTAssertEqual(captured, [0])
    }

    // MARK: - helper
    private enum AnyError: Error {
        case anyFailure
        case originalFailure
    }
}
