import Foundation

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

private enum UpdateError: LocalizedError {
    case invalidReleaseURL
    case invalidResponse
    case requestFailed(Int)
    case missingVersion

    var errorDescription: String? {
        switch self {
        case .invalidReleaseURL:
            return "The update check URL is invalid."
        case .invalidResponse:
            return "GitHub returned an invalid response."
        case .requestFailed(let statusCode):
            return "GitHub returned HTTP \(statusCode)."
        case .missingVersion:
            return "The latest release did not include a version."
        }
    }
}

@MainActor
@Observable
final class UpdateChecker {
    struct AvailableUpdate: Equatable {
        let version: String
        let releaseURL: URL
    }

    enum Status: Equatable {
        case idle
        case checking
        case updateAvailable(AvailableUpdate)
        case upToDate(latestVersion: String)
        case failed(String)
    }

    private static let latestReleaseURLString = "https://api.github.com/repos/angristan/MacThrottle/releases/latest"

    private(set) var status: Status = .idle

    var isChecking: Bool {
        status == .checking
    }

    func checkForUpdates() async {
        guard !isChecking else { return }

        status = .checking

        do {
            let release = try await fetchLatestRelease()
            let latestVersion = Self.normalizedVersion(release.tagName)

            guard !latestVersion.isEmpty else {
                throw UpdateError.missingVersion
            }

            if Self.isVersion(latestVersion, newerThan: Self.currentVersion) {
                status = .updateAvailable(
                    AvailableUpdate(version: latestVersion, releaseURL: release.htmlURL)
                )
            } else {
                status = .upToDate(latestVersion: latestVersion)
            }
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    private func fetchLatestRelease() async throws -> GitHubRelease {
        guard let latestReleaseURL = URL(string: Self.latestReleaseURLString) else {
            throw UpdateError.invalidReleaseURL
        }

        var request = URLRequest(url: latestReleaseURL, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("MacThrottle", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw UpdateError.requestFailed(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    private static var currentVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return normalizedVersion(version ?? "0")
    }

    private static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        let candidateComponents = versionComponents(from: candidate)
        let currentComponents = versionComponents(from: current)
        let componentCount = max(candidateComponents.count, currentComponents.count)

        for index in 0..<componentCount {
            let candidateValue = value(at: index, in: candidateComponents)
            let currentValue = value(at: index, in: currentComponents)

            if candidateValue != currentValue {
                return candidateValue > currentValue
            }
        }

        return false
    }

    private static func versionComponents(from version: String) -> [Int] {
        let coreVersion = normalizedVersion(version)
            .split(separator: "-", maxSplits: 1)
            .first ?? ""

        return coreVersion
            .split(separator: ".")
            .map { Int($0) ?? 0 }
    }

    private static func normalizedVersion(_ version: String) -> String {
        let trimmedVersion = version
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedVersion.lowercased().hasPrefix("v") {
            return String(trimmedVersion.dropFirst())
        }

        return trimmedVersion
    }

    private static func value(at index: Int, in components: [Int]) -> Int {
        index < components.count ? components[index] : 0
    }
}
