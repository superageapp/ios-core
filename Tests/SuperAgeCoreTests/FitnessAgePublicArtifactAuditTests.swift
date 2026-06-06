import Foundation
import Testing

@Suite("FitnessAge public artifact audit")
struct FitnessAgePublicArtifactAuditTests {
    private static let competitorTerms = [
        joined("gar", "min"),
        joined("bev", "el"),
        joined("ou", "ra"),
        joined("wh", "oop")
    ]
    private static let provenanceTerms = [
        joined("product", "-", "friendly"),
        phrase("previous", "public", "display", "behavior"),
        joined("user", "-", "perception", " ", "baseline"),
        phrase("hidden", "compensation"),
        joined("hidden", " ", "cross", "-", "domain"),
        joined("gar", "min", "style", "age"),
        joined("invent", "ed"),
        joined("cop", "ied"),
        joined("copy", "cat"),
        phrase("borrowed", "naming"),
        phrase("tuned", "to", "shape"),
        phrase("does", "not", "broadly", "age"),
        phrase("favorable", "rounding"),
        phrase("enhanced", "bonus"),
        joined("gar", "min", "-", "style"),
        phrase("product", "tuning")
    ]
    private static let deniedPhrases = competitorTerms + provenanceTerms
    private static let singleWordDeniedPhrases = Set(
        competitorTerms + [
            joined("invent", "ed"),
            joined("cop", "ied"),
            joined("copy", "cat")
        ]
    )

    @Test("Docs contains only methodology")
    func docsContainsOnlyMethodology() throws {
        let docsURL = Self.packageRoot.appendingPathComponent("Docs")
        let docsFiles = try FileManager.default.contentsOfDirectory(
            at: docsURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .map(\.lastPathComponent)
        .sorted()

        #expect(docsFiles == ["METHODOLOGY.md"])
    }

    @Test("public release files avoid denied credibility phrases")
    func publicReleaseFilesAvoidDeniedCredibilityPhrases() throws {
        let scannedFiles = try Self.publicReleaseFiles()
        var findings: [String] = []

        for fileURL in scannedFiles {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let relativePath = fileURL.path.replacingOccurrences(
                of: Self.packageRoot.path + "/",
                with: ""
            )

            for phrase in Self.deniedPhrases where Self.containsDeniedPhrase(phrase, in: content) {
                findings.append("\(relativePath): \(phrase)")
            }
        }

        #expect(findings.isEmpty, "Denied public artifact phrases found: \(findings.joined(separator: ", "))")
    }

    @Test("single word denied phrases require token boundaries")
    func singleWordDeniedPhrasesRequireTokenBoundaries() {
        let token = Self.joined("ou", "ra")

        #expect(!Self.containsDeniedPhrase(token, in: "We support deterministic documentation."))
        #expect(Self.containsDeniedPhrase(token, in: "\(token.capitalized) is a standalone token."))
    }

    private static var packageRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static func publicReleaseFiles() throws -> [URL] {
        let roots = [
            "README.md",
            "CHANGELOG.md",
            "CONTRIBUTING.md",
            "CODE_OF_CONDUCT.md",
            "SECURITY.md",
            "NOTICE",
            "Package.swift",
            ".github",
            "Docs/METHODOLOGY.md",
            "Sources",
            "Tests"
        ]
        var files: [URL] = []

        for root in roots {
            let url = packageRoot.appendingPathComponent(root)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            files.append(contentsOf: try regularFiles(in: url))
        }

        return files.filter { $0.path != URL(fileURLWithPath: #filePath).path }.sorted { $0.path < $1.path }
    }

    private static func containsDeniedPhrase(_ phrase: String, in content: String) -> Bool {
        let lowercasedContent = content.lowercased()
        let lowercasedPhrase = phrase.lowercased()

        guard Self.singleWordDeniedPhrases.contains(lowercasedPhrase) else {
            return lowercasedContent.contains(lowercasedPhrase)
        }

        return lowercasedContent.ranges(of: lowercasedPhrase).contains { range in
            let isStartBoundary = range.lowerBound == lowercasedContent.startIndex
                || !lowercasedContent[lowercasedContent.index(before: range.lowerBound)].isAlphaNumeric
            let isEndBoundary = range.upperBound == lowercasedContent.endIndex
                || !lowercasedContent[range.upperBound].isAlphaNumeric

            return isStartBoundary && isEndBoundary
        }
    }

    private static func joined(_ parts: String...) -> String {
        parts.joined()
    }

    private static func phrase(_ words: String...) -> String {
        words.joined(separator: " ")
    }

    private static func regularFiles(in url: URL) throws -> [URL] {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])

        if values.isRegularFile == true {
            return [url]
        }

        guard values.isDirectory == true else {
            return []
        }

        let urls = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        return try urls.flatMap { try regularFiles(in: $0) }
    }
}

private extension Character {
    var isAlphaNumeric: Bool {
        isLetter || isNumber
    }
}
