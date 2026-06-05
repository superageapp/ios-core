import Testing
@testable import SuperAgeCore

@Suite("SuperAgeCore package")
struct SuperAgeCoreTests {
    @Test("package exposes development version")
    func packageExposesDevelopmentVersion() {
        #expect(SuperAgeCore.version == "0.1.0-dev")
    }
}
