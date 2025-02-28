import XCTest

@testable import Leader_Key

final class ConfigValidatorTests: XCTestCase {

  // Test that a valid configuration passes validation
  func testValidConfiguration() {
    // Create a valid configuration
    let group = Group(
      key: nil,  // Root group doesn't need a key
      label: "Root",
      actions: [
        .action(Action(key: "a", type: .application, value: "/Applications/App1.app")),
        .action(Action(key: "b", type: .application, value: "/Applications/App2.app")),
        .group(
          Group(
            key: "c",
            label: "Subgroup",
            actions: [
              .action(Action(key: "d", type: .application, value: "/Applications/App3.app")),
              .action(Action(key: "e", type: .application, value: "/Applications/App4.app")),
            ]
          )),
      ]
    )

    // Validate the configuration
    let errors = ConfigValidator.validate(group: group)

    // Assert that there are no errors
    XCTAssertTrue(errors.isEmpty, "Valid configuration should not have validation errors")
  }

  // Test that empty keys are detected
  func testEmptyKeys() {
    let group = Group(
      key: nil,
      label: "Root",
      actions: [
        .action(Action(key: "", type: .application, value: "/Applications/App1.app")),
        .group(
          Group(
            key: "c",
            label: "Subgroup",
            actions: [
              .action(Action(key: "", type: .application, value: "/Applications/App3.app"))
            ]
          )),
      ]
    )

    let errors = ConfigValidator.validate(group: group)

    XCTAssertEqual(errors.count, 2, "Should detect two empty keys")
    XCTAssertEqual(errors.filter { $0.type == .emptyKey }.count, 2)

    // Check paths to ensure errors are at the correct locations
    let errorPaths = errors.map { $0.path }
    XCTAssertTrue(errorPaths.contains([0]), "Should have error at path [0]")
    XCTAssertTrue(errorPaths.contains([1, 0]), "Should have error at path [1, 0]")
  }

  // Test that non-single-character keys are detected
  func testNonSingleCharacterKeys() {
    let group = Group(
      key: nil,
      label: "Root",
      actions: [
        .action(Action(key: "ab", type: .application, value: "/Applications/App1.app")),
        .group(
          Group(
            key: "cd",
            label: "Subgroup",
            actions: []
          )),
      ]
    )

    let errors = ConfigValidator.validate(group: group)

    XCTAssertEqual(errors.count, 2, "Should detect two non-single-character keys")
    XCTAssertEqual(errors.filter { $0.type == .nonSingleCharacterKey }.count, 2)

    // Check paths
    let errorPaths = errors.map { $0.path }
    XCTAssertTrue(errorPaths.contains([0]), "Should have error at path [0]")
    XCTAssertTrue(errorPaths.contains([1]), "Should have error at path [1]")
  }

  // Test that duplicate keys within the same group are detected
  func testDuplicateKeys() {
    let group = Group(
      key: nil,
      label: "Root",
      actions: [
        .action(Action(key: "a", type: .application, value: "/Applications/App1.app")),
        .action(Action(key: "a", type: .application, value: "/Applications/App2.app")),
        .group(
          Group(
            key: "c",
            label: "Subgroup",
            actions: [
              .action(Action(key: "d", type: .application, value: "/Applications/App3.app")),
              .action(Action(key: "d", type: .application, value: "/Applications/App4.app")),
            ]
          )),
      ]
    )

    let errors = ConfigValidator.validate(group: group)

    // We should have 4 errors: 2 for the duplicate 'a' keys and 2 for the duplicate 'd' keys
    XCTAssertEqual(errors.count, 4, "Should detect four errors for duplicate keys")
    XCTAssertEqual(errors.filter { $0.type == .duplicateKey }.count, 4)

    // Check paths
    let errorPaths = errors.map { $0.path }
    XCTAssertTrue(errorPaths.contains([0]), "Should have error at path [0]")
    XCTAssertTrue(errorPaths.contains([1]), "Should have error at path [1]")
    XCTAssertTrue(errorPaths.contains([2, 0]), "Should have error at path [2, 0]")
    XCTAssertTrue(errorPaths.contains([2, 1]), "Should have error at path [2, 1]")
  }

  // Test that the findItem function correctly locates items
  func testFindItem() {
    let group = Group(
      key: nil,
      label: "Root",
      actions: [
        .action(Action(key: "a", type: .application, value: "/Applications/App1.app")),
        .group(
          Group(
            key: "b",
            label: "Subgroup",
            actions: [
              .action(Action(key: "c", type: .application, value: "/Applications/App2.app"))
            ]
          )),
      ]
    )

    // Find the root group
    if case .group(let foundGroup) = ConfigValidator.findItem(in: group, at: []) {
      XCTAssertEqual(foundGroup.label, "Root")
    } else {
      XCTFail("Should find the root group")
    }

    // Find the first action
    if case .action(let foundAction) = ConfigValidator.findItem(in: group, at: [0]) {
      XCTAssertEqual(foundAction.key, "a")
      XCTAssertEqual(foundAction.value, "/Applications/App1.app")
    } else {
      XCTFail("Should find the first action")
    }

    // Find the subgroup
    if case .group(let foundGroup) = ConfigValidator.findItem(in: group, at: [1]) {
      XCTAssertEqual(foundGroup.key, "b")
      XCTAssertEqual(foundGroup.label, "Subgroup")
    } else {
      XCTFail("Should find the subgroup")
    }

    // Find the action in the subgroup
    if case .action(let foundAction) = ConfigValidator.findItem(in: group, at: [1, 0]) {
      XCTAssertEqual(foundAction.key, "c")
      XCTAssertEqual(foundAction.value, "/Applications/App2.app")
    } else {
      XCTFail("Should find the action in the subgroup")
    }

    // Test with an invalid path
    XCTAssertNil(ConfigValidator.findItem(in: group, at: [3]), "Should return nil for invalid path")
    XCTAssertNil(
      ConfigValidator.findItem(in: group, at: [0, 0]),
      "Should return nil when path goes through an action")
  }
}
