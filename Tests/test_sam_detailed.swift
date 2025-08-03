import Foundation
import XCTest

// Detailed SAM.gov API test with full response parsing
final class DetailedSAMTest: XCTestCase {
    func testDetailedSAMAPIAnalysis() async throws {
        print("🔍 Detailed SAM.gov API Analysis - CAGE Code: 5BVH3")
        print(String(repeating: "=", count: 60))

        let apiKey = "zBy0Oy4TmGnzgqEWeKoRiifzDm9jotNwAitkOp89"
        let cageCode = "5BVH3"
        let baseURL = "https://api.sam.gov/entity-information/v3"

        guard var components = URLComponents(string: "\(baseURL)/entities") else {
            XCTFail("Failed to create URL components")
            return
        }
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "cageCode", value: cageCode),
            URLQueryItem(name: "format", value: "JSON")
        ]

        guard let url = components.url else {
            print("❌ Failed to construct URL")
            return
        }

        do {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15
            let session = URLSession(configuration: config)

            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return
            }

            print("📊 HTTP Status: \(httpResponse.statusCode)")
            print("📊 Response Size: \(data.count) bytes")

            if 200...299 ~= httpResponse.statusCode {
                // Pretty print the JSON response
                if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                   let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                   let prettyString = String(data: prettyData, encoding: .utf8) {

                    print("\n📋 Complete API Response:")
                    print(prettyString)
                } else {
                    print("\n📋 Raw Response:")
                    print(String(data: data, encoding: .utf8) ?? "Unable to decode response")
                }

                // Parse for entity data
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("\n🎯 Analysis Results:")

                    if let totalRecords = json["totalRecords"] as? Int {
                        print("   📊 Total Records Found: \(totalRecords)")

                        if totalRecords == 0 {
                            print("   ⚠️  No entity found for CAGE Code: \(cageCode)")
                            print("   💡 This could mean:")
                            print("      • CAGE Code doesn't exist in SAM.gov")
                            print("      • Entity registration is expired/inactive")
                            print("      • CAGE Code format is incorrect")
                        }
                    }

                    if let entityData = json["entityData"] as? [[String: Any]], !entityData.isEmpty {
                        print("   ✅ Entity data found - processing...")
                        // Entity details would be processed here
                    } else {
                        print("   📝 No entity data in response")
                    }

                    // Check for error messages
                    if let error = json["error"] as? [String: Any] {
                        print("   ❌ API Error: \(error)")
                    }

                    // Check for API version info
                    if let links = json["links"] as? [String: Any] {
                        print("   🔗 API Links: \(links)")
                    }
                }

            } else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Error response: \(responseString)")
                }
            }

        } catch {
            print("❌ Network Error: \(error)")
        }

        print("\n" + String(repeating: "=", count: 60))
        print("🏁 Detailed API Analysis Complete")
    }
}
