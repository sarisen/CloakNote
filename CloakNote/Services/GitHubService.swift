import Foundation

final class GitHubService {
    private var token: String = ""
    private var owner: String = ""
    private var repo: String = ""

    private let baseURL = "https://api.github.com"

    func configure(token: String, owner: String, repo: String) {
        self.token = token
        self.owner = owner
        self.repo = repo
    }

    var isConfigured: Bool {
        !token.isEmpty && !owner.isEmpty && !repo.isEmpty
    }

    func testConnection() async throws -> Bool {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 200 { return true }
        if status == 404 { return false }
        throw GitHubError.apiError(statusCode: status, message: String(data: data, encoding: .utf8) ?? "")
    }

    func listEntries() async throws -> [GitHubFile] {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/contents/entries")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 404 { return [] }
        if status >= 400 {
            throw GitHubError.apiError(statusCode: status, message: String(data: data, encoding: .utf8) ?? "")
        }
        return try JSONDecoder().decode([GitHubFile].self, from: data)
    }

    func fetchEntry(filename: String) async throws -> (content: String, sha: String) {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/contents/entries/\(filename)")!
        let (data, _) = try await request(url: url, method: "GET")
        let file = try JSONDecoder().decode(GitHubFileContent.self, from: data)
        let content = file.content.replacingOccurrences(of: "\n", with: "")
        guard let decoded = Data(base64Encoded: content),
              let text = String(data: decoded, encoding: .utf8) else {
            throw GitHubError.invalidContent
        }
        return (text, file.sha)
    }

    func pushEntry(filename: String, content: String, sha: String?, message: String) async throws {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/contents/entries/\(filename)")!
        let contentBase64 = Data(content.utf8).base64EncodedString()
        var body: [String: Any] = [
            "message": message,
            "content": contentBase64
        ]
        if let sha = sha {
            body["sha"] = sha
        }
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        _ = try await request(url: url, method: "PUT", body: bodyData)
    }

    func deleteEntry(filename: String, sha: String, message: String? = nil) async throws {
        let languageManager = LanguageManager()
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/contents/entries/\(filename)")!
        let body: [String: Any] = [
            "message": message ?? "\(languageManager.deleteFileCommitPrefix): \(filename)",
            "sha": sha
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        _ = try await request(url: url, method: "DELETE", body: bodyData)
    }

    func createRepo(name: String) async throws {
        let languageManager = LanguageManager()
        let url = URL(string: "\(baseURL)/user/repos")!
        let body: [String: Any] = [
            "name": name,
            "private": true,
            "description": languageManager.privateRepoDescription,
            "auto_init": true
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        _ = try await request(url: url, method: "POST", body: bodyData)
    }

    func currentUser() async throws -> String {
        let url = URL(string: "\(baseURL)/user")!
        let (data, _) = try await request(url: url, method: "GET")
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["login"] as? String ?? ""
    }

    private func request(url: URL, method: String, body: Data? = nil) async throws -> (Data, URLResponse) {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        if let body = body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw GitHubError.apiError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "")
        }
        return (data, response)
    }

    struct GitHubFile: Codable, Identifiable {
        let name: String
        let sha: String
        let size: Int
        var id: String { name }
    }

    struct GitHubFileContent: Codable {
        let name: String
        let sha: String
        let content: String
    }

    enum GitHubError: LocalizedError {
        case invalidContent
        case apiError(statusCode: Int, message: String)

        var errorDescription: String? {
            let languageManager = LanguageManager()
            switch self {
            case .invalidContent:
                return languageManager.invalidGitHubFileContent
            case .apiError(let code, let msg):
                return languageManager.gitHubAPIError(code: code, message: msg)
            }
        }
    }
}
