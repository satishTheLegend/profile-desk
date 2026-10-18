import XCTest
import WebKit

/// Synthetic same-origin tests. No WhatsApp account, pairing or message operation occurs.
@MainActor
final class NamedStoreTests: XCTestCase {
    private func removeFixtureStore(_ identifier: UUID) async throws {
        // Final teardown can race native cookie-file disposal after releasing
        // every store. Retry only this fixture's generated IDs, and still require
        // public inventory to confirm that cleanup actually completed.
        for attempt in 0..<5 {
            if !(await WKWebsiteDataStore.allDataStoreIdentifiers).contains(identifier) { return }
            do { try await WKWebsiteDataStore.remove(forIdentifier: identifier) }
            catch {
                if !(await WKWebsiteDataStore.allDataStoreIdentifiers).contains(identifier) { return }
                if attempt == 4 { throw error }
            }
            if !(await WKWebsiteDataStore.allDataStoreIdentifiers).contains(identifier) { return }
            try await Task.sleep(for: .milliseconds(100 * (attempt + 1)))
        }
        XCTFail("Fixture-owned named store remained after bounded cleanup")
    }

    func testTenNamedStoresKeepSameOriginHttpOnlyCookiesIsolated() async throws {
        let identifiers = (0..<10).map { _ in UUID() }
        // Keep native cookie-store clients alive through their assertions. Disk
        // persistence after view disposal is tested by the hosted HTTPS harness.
        var stores: [WKWebsiteDataStore?] = identifiers.map { WKWebsiteDataStore(forIdentifier: $0) }
        for (index, identifier) in identifiers.enumerated() {
            let store = try XCTUnwrap(stores[index])
            XCTAssertEqual(store.identifier,identifier)
            let cookie = try XCTUnwrap(HTTPCookie(properties: [
                .domain:"harness.profiledesk.invalid", .path:"/", .name:"synthetic_profile",
                .value:"marker-\(index)", .secure:"TRUE", .expires:Date(timeIntervalSinceNow:3600),
                HTTPCookiePropertyKey("HttpOnly"):"TRUE"
            ]))
            await store.httpCookieStore.setCookie(cookie)
        }
        let inventory = await WKWebsiteDataStore.allDataStoreIdentifiers
        XCTAssertTrue(Set(identifiers).isSubset(of:Set(inventory)))
        for (index, identifier) in identifiers.enumerated() {
            let cookies = await WKWebsiteDataStore(forIdentifier:identifier).httpCookieStore.allCookies()
            let markers = cookies.filter { $0.name == "synthetic_profile" }
            XCTAssertEqual(markers.count,1)
            XCTAssertEqual(markers.first?.value,"marker-\(index)")
            XCTAssertEqual(markers.first?.isHTTPOnly,true)
        }
        stores[4] = nil
        try await WKWebsiteDataStore.remove(forIdentifier:identifiers[4])
        let after = await WKWebsiteDataStore.allDataStoreIdentifiers
        XCTAssertFalse(after.contains(identifiers[4]))
        for (index, identifier) in identifiers.enumerated() where index != 4 {
            let cookies = await WKWebsiteDataStore(forIdentifier:identifier).httpCookieStore.allCookies()
            XCTAssertEqual(cookies.first { $0.name == "synthetic_profile" }?.value,"marker-\(index)")
        }
        let replacement = UUID()
        let freshCookies = await WKWebsiteDataStore(forIdentifier:replacement).httpCookieStore.allCookies()
        XCTAssertTrue(freshCookies.isEmpty)
        stores.removeAll()
        for identifier in identifiers where identifier != identifiers[4] { try await removeFixtureStore(identifier) }
        try await removeFixtureStore(replacement)
    }

    func testNamedStoreIsBoundBeforeViewConstructionAndSurvivesViewDisposal() async throws {
        let identifier = UUID()
        do {
            let config = WKWebViewConfiguration()
            config.websiteDataStore = WKWebsiteDataStore(forIdentifier:identifier)
            var view: WKWebView? = WKWebView(frame:.zero,configuration:config)
            XCTAssertEqual(view?.configuration.websiteDataStore.identifier,identifier)
            view?.stopLoading(); view?.navigationDelegate = nil; view?.uiDelegate = nil; view?.removeFromSuperview(); view = nil
        }
        let inventory = await WKWebsiteDataStore.allDataStoreIdentifiers
        XCTAssertTrue(inventory.contains(identifier))
        try await WKWebsiteDataStore.remove(forIdentifier:identifier)
        let remaining = await WKWebsiteDataStore.allDataStoreIdentifiers
        XCTAssertFalse(remaining.contains(identifier))
    }
}
