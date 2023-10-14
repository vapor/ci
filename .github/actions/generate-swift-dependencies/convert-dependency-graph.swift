#!/usr/bin/env swift -enable-upcoming-feature ExistentialAny -enable-upcoming-feature BareSlashRegexLiterals

import Foundation

struct PackageDependency: Codable {
    let identity: String, name: String, url: String, version: String, path: String
    let dependencies: [PackageDependency]
}

struct SwiftPUrl: Codable, RawRepresentable {
    let scheme: String, type: String, source: String, name: String, version: String
    var rawValue: String { "\(self.scheme):\(self.type)/\(self.source)/\(self.name)@\(self.version)" }
    
    init?(rawValue raw: String) {
        guard let match = raw.wholeMatch(of: #/pkg:swift/(?<sp>[^/]+)/(?<nm>[^@]+)@(?<ver>.+)/#) else { return nil }
        self.init(source: .init(match.sp), name: .init(match.nm), version: .init(match.ver))
    }    
    init(source: String, name: String, version: String) {
        (self.scheme, self.type) = ("pkg", "swift")
        (self.source, self.name, self.version) = (source, name, version)
    }
    init(with url: URL, version: String) {
        (self.scheme, self.type) = ("pkg", "swift")
        self.source = "\(url.host ?? "localhost")\(url.deletingLastPathComponent().path)"
        self.name = (url.pathExtension == "git" ? url.deletingPathExtension() : url).lastPathComponent
        self.version = version
    }
}

struct GithubDependencyGraph: Codable {
    struct Job: Codable { let correlator: String, id: String }
    struct Detector: Codable { let name: String, version: String, url: String }
    struct Manifest: Codable {
        struct File: Codable { let source_location: String }
        struct Package: Codable { let package_url: SwiftPUrl, dependencies: [String] }
        let name: String, file: File, resolved: [String: Package]
    }
    let owner: String, repo: String, version: Int, sha: String, ref: String,
        job: Job, detector: Detector, scanned: Date, manifests: [String: Manifest]
}

func env(_ name: String) -> String? { ProcessInfo.processInfo.environment[name] }

func main() {
    let decoder = JSONDecoder(), encoder = JSONEncoder()
    decoder.dateDecodingStrategy = .iso8601
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]

    guard let owner = env("OWNER"),           let repo = env("REPO"),
          let branch = env("BRANCH"),         let commit = env("COMMIT"),
          let correlator = env("CORRELATOR"), let runId = env("RUN_ID"),
          let detector = env("GITHUB_ACTION"),
          let detectorVer = env("GITHUB_ACTION_REF"),
          let detectorRepo = env("GITHUB_ACTION_REPOSITORY"),
          let serverUrl = env("GITHUB_SERVER_URL")
    else {
        try? FileHandle.standardError.write(contentsOf: Array("Incomplete environment.\n".utf8))
        exit(1)
    }
    
    let dependencies = try! decoder.decode(
        PackageDependency.self,
        from: FileHandle.standardInput.readToEnd() ?? .init()
    ).dependencies
    
    var resolved = [String: GithubDependencyGraph.Manifest.Package]()
    
    func handleDeps(_ dependencies: [PackageDependency]) {
        for dep in dependencies where !resolved.keys.contains(dep.identity) {
            handleDeps(dep.dependencies)
            guard !resolved.keys.contains(dep.identity) else { continue }
            guard let url = URL(string: dep.url) else {
                try? FileHandle.standardError.write(contentsOf: Array("Invalid URL for package \(dep.identity)\n".utf8))
                exit(1)
            }
            resolved[dep.identity] = .init(
                package_url: .init(with: url, version: dep.version),
                dependencies: dep.dependencies.map(\.identity).sorted()
            )
        }
    }
    handleDeps(dependencies)

    let graph = GithubDependencyGraph(
        owner: owner, repo: repo, version: 0, sha: commit, ref: branch,
        job: .init(correlator: correlator, id: runId),
        detector: .init(
            name: .init(detector.prefix(while: { $0 != "_" })),
            version: detectorVer,
            url: "\(serverUrl)/\(detectorRepo)"
        ),
        scanned: Date(),
        manifests: ["Package.resolved": .init(
            name: "Package.resolved",
            file: .init(source_location: "Package.resolved"),
            resolved: resolved
        )]
    )
    
    print(String(decoding: try! encoder.encode(graph), as: UTF8.self))
}

main()
