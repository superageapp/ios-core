import Testing
@testable import SuperAgeCore

@Suite("SuperAgeCore package")
struct SuperAgeCoreTests {
    @Test("package exposes the released version")
    func packageExposesReleasedVersion() {
        #expect(SuperAgeCoreInfo.version == "0.4.0")
    }
}
