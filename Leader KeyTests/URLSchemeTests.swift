import XCTest
@testable import Leader_Key

final class URLSchemeTests: XCTestCase {
  var mockAppDelegate: MockAppDelegate!

  override func setUp() {
    super.setUp()
    mockAppDelegate = MockAppDelegate()
  }

  override func tearDown() {
    mockAppDelegate = nil
    super.tearDown()
  }

  // MARK: - Configuration Management Tests

  func testConfigReloadURL() {
    let url = URL(string: "leaderkey://config-reload")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    XCTAssertTrue(mockAppDelegate.configReloadCalled)
    XCTAssertFalse(mockAppDelegate.settingsCalled)
  }

  func testConfigRevealURL() {
    let url = URL(string: "leaderkey://config-reveal")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    XCTAssertTrue(mockAppDelegate.configRevealCalled)
    XCTAssertFalse(mockAppDelegate.settingsCalled)
  }

  // MARK: - Window Control Tests

  func testActivateURL() {
    let url = URL(string: "leaderkey://activate")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    XCTAssertTrue(mockAppDelegate.activateCalled)
    XCTAssertFalse(mockAppDelegate.hideCalled)
  }

  func testHideURL() {
    let url = URL(string: "leaderkey://hide")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    XCTAssertTrue(mockAppDelegate.hideCalled)
    XCTAssertFalse(mockAppDelegate.activateCalled)
  }

  func testResetURL() {
    let url = URL(string: "leaderkey://reset")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    XCTAssertTrue(mockAppDelegate.resetCalled)
  }

  // MARK: - Settings & Info Tests

  func testSettingsURL() {
    let url = URL(string: "leaderkey://settings")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    XCTAssertTrue(mockAppDelegate.settingsCalled)
  }

  func testAboutURL() {
    let url = URL(string: "leaderkey://about")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    XCTAssertTrue(mockAppDelegate.aboutCalled)
  }

  // MARK: - Navigation Tests

  func testNavigateWithKeys() {
    let url = URL(string: "leaderkey://navigate?keys=a,b,c")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    XCTAssertTrue(mockAppDelegate.navigateCalled)
    XCTAssertEqual(mockAppDelegate.lastNavigateKeys, ["a", "b", "c"])
    XCTAssertTrue(mockAppDelegate.lastNavigateExecute)
  }

  func testNavigateWithExecuteFalse() {
    let url = URL(string: "leaderkey://navigate?keys=a,b&execute=false")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    XCTAssertTrue(mockAppDelegate.navigateCalled)
    XCTAssertEqual(mockAppDelegate.lastNavigateKeys, ["a", "b"])
    XCTAssertFalse(mockAppDelegate.lastNavigateExecute)
  }

  func testNavigateWithExecuteTrue() {
    let url = URL(string: "leaderkey://navigate?keys=x,y&execute=true")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    XCTAssertTrue(mockAppDelegate.navigateCalled)
    XCTAssertEqual(mockAppDelegate.lastNavigateKeys, ["x", "y"])
    XCTAssertTrue(mockAppDelegate.lastNavigateExecute)
  }

  func testNavigateWithSingleKey() {
    let url = URL(string: "leaderkey://navigate?keys=z")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    XCTAssertTrue(mockAppDelegate.navigateCalled)
    XCTAssertEqual(mockAppDelegate.lastNavigateKeys, ["z"])
    XCTAssertTrue(mockAppDelegate.lastNavigateExecute)
  }

  // MARK: - Invalid URL Tests

  func testInvalidScheme() {
    let url = URL(string: "invalid://settings")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    XCTAssertFalse(mockAppDelegate.settingsCalled)
  }

  func testUnknownHost() {
    let url = URL(string: "leaderkey://unknown")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    // Should show the window but not call any specific handlers
    XCTAssertTrue(mockAppDelegate.showCalled)
    XCTAssertFalse(mockAppDelegate.settingsCalled)
    XCTAssertFalse(mockAppDelegate.configReloadCalled)
  }

  func testNavigateWithoutKeys() {
    let url = URL(string: "leaderkey://navigate")!
    mockAppDelegate.application(NSApplication.shared, open: [url])

    // Should show window but not navigate
    XCTAssertTrue(mockAppDelegate.showCalled)
    XCTAssertFalse(mockAppDelegate.navigateCalled)
  }

  // MARK: - Multiple URL Tests

  func testMultipleURLsProcessedInOrder() {
    let urls = [
      URL(string: "leaderkey://config-reload")!,
      URL(string: "leaderkey://settings")!
    ]
    mockAppDelegate.application(NSApplication.shared, open: urls)

    XCTAssertTrue(mockAppDelegate.configReloadCalled)
    XCTAssertTrue(mockAppDelegate.settingsCalled)
  }
}

// MARK: - Mock AppDelegate

class MockAppDelegate: NSObject {
  var settingsCalled = false
  var aboutCalled = false
  var configReloadCalled = false
  var configRevealCalled = false
  var activateCalled = false
  var hideCalled = false
  var resetCalled = false
  var navigateCalled = false
  var showCalled = false

  var lastNavigateKeys: [String]?
  var lastNavigateExecute: Bool = true

  func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      handleURL(url)
    }
  }

  private func handleURL(_ url: URL) {
    guard url.scheme == "leaderkey" else { return }

    if url.host == "settings" {
      settingsCalled = true
      return
    }
    if url.host == "about" {
      aboutCalled = true
      return
    }
    if url.host == "config-reload" {
      configReloadCalled = true
      return
    }
    if url.host == "config-reveal" {
      configRevealCalled = true
      return
    }
    if url.host == "activate" {
      activateCalled = true
      return
    }
    if url.host == "hide" {
      hideCalled = true
      return
    }
    if url.host == "reset" {
      resetCalled = true
      return
    }

    showCalled = true

    if url.host == "navigate",
       let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
       let queryItems = components.queryItems,
       let keysParam = queryItems.first(where: { $0.name == "keys" })?.value
    {
      let keys = keysParam.split(separator: ",").map(String.init)
      let shouldExecute = queryItems.first(where: { $0.name == "execute" })?.value != "false"

      navigateCalled = true
      lastNavigateKeys = keys
      lastNavigateExecute = shouldExecute
    }
  }
}
