import Foundation

struct AppVersionInfo {
    static let current = AppVersionInfo(bundle: .main)

    let version: String
    let build: String
    let buildTime: String
    let gitCommit: String

    var displayText: String {
        "v\(version) (\(build)) · \(buildTime)"
    }

    var detailText: String {
        gitCommit.isEmpty ? displayText : "\(displayText) · \(gitCommit)"
    }

    init(bundle: Bundle) {
        let info = bundle.infoDictionary ?? [:]
        version = info["CFBundleShortVersionString"] as? String ?? "dev"
        build = info["CFBundleVersion"] as? String ?? "local"
        buildTime = info["DSBuildTime"] as? String ?? "unbuilt"
        gitCommit = info["DSGitCommit"] as? String ?? ""
    }
}
