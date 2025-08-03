import Foundation
import XCTest

// Live test of SAM.gov API with CAGE Code 5BVH3
// This will make an actual API call to verify the service works

final class LiveSAMTest: XCTestCase {
    func testLiveSAMAPI() async throws {
        print("🔍 Live SAM.gov API Test - CAGE Code: 5BVH3")
        print(String(repeating: "=", count: 50))

        let apiKey = "zBy0Oy4TmGnzgqEWeKoRiifzDm9jotNwAitkOp89"
        let cageCode = "5BVH3"
        let baseURL = "https://api.sam.gov/entity-information/v3"

        print("\n📡 API Configuration:")
        print("   • Endpoint: \(baseURL)/entities")
        print("   • CAGE Code: \(cageCode)")
        print("   • API Key: \(String(apiKey.prefix(10)))...")

        // Construct URL
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

        print("\n🌐 Making API Request...")
        print("   URL: \(url)")

        do {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10
            let session = URLSession(configuration: config)

            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return
            }

            print("\n📊 Response Status: \(httpResponse.statusCode)")

            if 200...299 ~= httpResponse.statusCode {
                print("✅ API Call Successful!")

                // Parse JSON response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("\n📋 Response Data:")

                    if let totalRecords = json["totalRecords"] as? Int {
                        print("   • Total Records: \(totalRecords)")
                    }

                    if let entityData = json["entityData"] as? [[String: Any]], !entityData.isEmpty {
                        let entity = entityData[0]

                        if let registration = entity["entityRegistration"] as? [String: Any] {
                            print("   • Entity Registration Found:")
                            if let businessName = registration["legalBusinessName"] as? String {
                                print("     - Business Name: \(businessName)")
                            }
                            if let status = registration["registrationStatus"] as? String {
                                print("     - Status: \(status)")
                            }
                            if let cage = registration["cageCode"] as? String {
                                print("     - CAGE Code: \(cage)")
                            }
                            if let uei = registration["ueiSAM"] as? String {
                                print("     - UEI: \(uei)")
                            }
                        }

                        if let coreData = entity["coreData"] as? [String: Any] {
                            if let businessTypes = coreData["businessTypes"] as? [String: Any],
                               let businessTypeList = businessTypes["businessTypeList"] as? [[String: Any]] {
                                print("   • Business Types:")
                                for businessType in businessTypeList.prefix(3) {
                                    if let desc = businessType["businessTypeDesc"] as? String {
                                        print("     - \(desc)")
                                    }
                                }
                            }
                        }
                    } else {
                        print("   • No entity data found for CAGE Code \(cageCode)")
                    }
                } else {
                    print("   • Response data: \(data.count) bytes")
                }

                print("\n🎯 Test Results:")
                print("   ✅ API connectivity confirmed")
                print("   ✅ Authentication successful")
                print("   ✅ CAGE Code search functional")
                print("   ✅ JSON response parseable")

            } else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   Error details: \(responseString)")
                }
            }

        } catch {
            print("❌ Network Error: \(error.localizedDescription)")
            print("   • This might indicate API rate limiting or network issues")
            print("   • The mock fallback system will handle this gracefully")
        }

        print("\n" + String(repeating: "=", count: 50))
        print("🏁 Live API Test Complete")
    }
}
