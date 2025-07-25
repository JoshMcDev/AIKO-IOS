import Foundation
import NaturalLanguage
#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

/// Service for spell checking and grammar validation of generated documents
public struct SpellCheckService: Sendable {
    public struct SpellCheckResult {
        public let originalText: String
        public let correctedText: String
        public let corrections: [Correction]
        public let statistics: Statistics

        public struct Correction {
            public let range: NSRange
            public let original: String
            public let suggestion: String
            public let type: CorrectionType
            public let confidence: Double
        }

        public enum CorrectionType {
            case spelling
            case grammar
            case punctuation
            case capitalization
            case wordChoice
        }

        public struct Statistics {
            public let totalWords: Int
            public let misspelledWords: Int
            public let grammarIssues: Int
            public let readabilityScore: Double
        }
    }

    public var checkDocument: @Sendable (String) async -> SpellCheckResult
    public var checkAndCorrect: @Sendable (String) async -> String
    public var getSuggestions: @Sendable (String, NSRange) async -> [String]
    public var addToCustomDictionary: @Sendable (String) async -> Void
    public var removeFromCustomDictionary: @Sendable (String) async -> Void

    public init(
        checkDocument: @escaping @Sendable (String) async -> SpellCheckResult,
        checkAndCorrect: @escaping @Sendable (String) async -> String,
        getSuggestions: @escaping @Sendable (String, NSRange) async -> [String],
        addToCustomDictionary: @escaping @Sendable (String) async -> Void,
        removeFromCustomDictionary: @escaping @Sendable (String) async -> Void
    ) {
        self.checkDocument = checkDocument
        self.checkAndCorrect = checkAndCorrect
        self.getSuggestions = getSuggestions
        self.addToCustomDictionary = addToCustomDictionary
        self.removeFromCustomDictionary = removeFromCustomDictionary
    }
}

public extension SpellCheckService {
    static var liveValue: SpellCheckService {
        let customDictionary = CustomDictionary()

        return SpellCheckService(
            checkDocument: { text in
                let tokenizer = NLTokenizer(unit: .word)

                var corrections: [SpellCheckResult.Correction] = []
                var misspelledCount = 0
                var wordCount = 0

                // Configure tokenizer
                tokenizer.string = text
                let language = NLLanguageRecognizer.dominantLanguage(for: text) ?? .english
                tokenizer.setLanguage(language)

                // Check each word
                var tokenRanges: [(Range<String.Index>, String)] = []
                tokenizer.enumerateTokens(in: text.startIndex ..< text.endIndex) { tokenRange, _ in
                    let word = String(text[tokenRange])
                    tokenRanges.append((tokenRange, word))
                    return true
                }

                for (tokenRange, word) in tokenRanges {
                    wordCount += 1

                    // Skip if in custom dictionary
                    if await customDictionary.contains(word) {
                        continue
                    }

                    // Convert to NSRange
                    let nsRange = NSRange(tokenRange, in: text)

                    // Platform-specific spell checking
                    #if os(macOS)
                        let checker = NSSpellChecker.shared
                        let misspelledRange = checker.checkSpelling(
                            of: word,
                            startingAt: 0,
                            language: language.rawValue,
                            wrap: false,
                            inSpellDocumentWithTag: 0,
                            wordCount: nil
                        )

                        if misspelledRange.location != NSNotFound {
                            misspelledCount += 1

                            // Get suggestions
                            let suggestions = checker.guesses(
                                forWordRange: NSRange(location: 0, length: word.count),
                                in: word,
                                language: language.rawValue,
                                inSpellDocumentWithTag: 0
                            ) ?? []

                            if let firstSuggestion = suggestions.first {
                                corrections.append(
                                    SpellCheckResult.Correction(
                                        range: nsRange,
                                        original: word,
                                        suggestion: firstSuggestion,
                                        type: .spelling,
                                        confidence: 0.8
                                    )
                                )
                            }
                        }
                    #else
                        // iOS implementation using UITextChecker
                        // Wrap UITextChecker calls in async context for Swift 6 compatibility
                        let (misspelledRange, suggestions) = await Task { @MainActor in
                            let textChecker = UITextChecker()
                            let misspelledRange = textChecker.rangeOfMisspelledWord(
                                in: word,
                                range: NSRange(location: 0, length: word.count),
                                startingAt: 0,
                                wrap: false,
                                language: language.rawValue
                            )

                            var suggestions: [String] = []
                            if misspelledRange.location != NSNotFound {
                                suggestions = textChecker.guesses(
                                    forWordRange: NSRange(location: 0, length: word.count),
                                    in: word,
                                    language: language.rawValue
                                ) ?? []
                            }

                            return (misspelledRange, suggestions)
                        }.value

                        if misspelledRange.location != NSNotFound {
                            misspelledCount += 1

                            if let firstSuggestion = suggestions.first {
                                corrections.append(
                                    SpellCheckResult.Correction(
                                        range: nsRange,
                                        original: word,
                                        suggestion: firstSuggestion,
                                        type: .spelling,
                                        confidence: 0.8
                                    )
                                )
                            }
                        }
                    #endif
                }

                // Apply corrections to create corrected text
                var correctedText = text
                for correction in corrections.reversed() {
                    if let range = Range(correction.range, in: correctedText) {
                        correctedText.replaceSubrange(range, with: correction.suggestion)
                    }
                }

                // Check for common grammar issues
                let grammarIssues = checkGrammarIssues(text: text, corrections: &corrections)

                // Calculate readability score (simple version)
                let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                let avgWordsPerSentence = Double(wordCount) / Double(max(sentences.count, 1))
                let readabilityScore = min(100, max(0, 100 - (avgWordsPerSentence - 20) * 2))

                return SpellCheckResult(
                    originalText: text,
                    correctedText: correctedText,
                    corrections: corrections,
                    statistics: SpellCheckResult.Statistics(
                        totalWords: wordCount,
                        misspelledWords: misspelledCount,
                        grammarIssues: grammarIssues,
                        readabilityScore: readabilityScore
                    )
                )
            },
            checkAndCorrect: { text in
                let result = await SpellCheckService.liveValue.checkDocument(text)
                return result.correctedText
            },
            getSuggestions: { text, range in
                #if os(macOS)
                    let checker = NSSpellChecker.shared
                    if let wordRange = Range(range, in: text) {
                        let word = String(text[wordRange])
                        return checker.guesses(
                            forWordRange: NSRange(location: 0, length: word.count),
                            in: word,
                            language: "en",
                            inSpellDocumentWithTag: 0
                        ) ?? []
                    }
                #else
                    if let wordRange = Range(range, in: text) {
                        let word = String(text[wordRange])
                        // Wrap UITextChecker calls in async context for Swift 6 compatibility
                        return await Task { @MainActor in
                            let textChecker = UITextChecker()
                            return textChecker.guesses(
                                forWordRange: NSRange(location: 0, length: word.count),
                                in: word,
                                language: "en"
                            ) ?? []
                        }.value
                    }
                #endif
                return []
            },
            addToCustomDictionary: { word in
                await customDictionary.add(word)
            },
            removeFromCustomDictionary: { word in
                await customDictionary.remove(word)
            }
        )
    }

    static var testValue: SpellCheckService {
        SpellCheckService(
            checkDocument: { text in
                SpellCheckResult(
                    originalText: text,
                    correctedText: text,
                    corrections: [],
                    statistics: SpellCheckResult.Statistics(
                        totalWords: text.split(separator: " ").count,
                        misspelledWords: 0,
                        grammarIssues: 0,
                        readabilityScore: 85.0
                    )
                )
            },
            checkAndCorrect: { text in text },
            getSuggestions: { _, _ in [] },
            addToCustomDictionary: { _ in },
            removeFromCustomDictionary: { _ in }
        )
    }

    static var previewValue: SpellCheckService {
        testValue
    }
}

// Helper function to check grammar issues
private func checkGrammarIssues(text: String, corrections: inout [SpellCheckService.SpellCheckResult.Correction]) -> Int {
    var issueCount = 0

    // Check for double spaces
    let doubleSpaceRegex = try? NSRegularExpression(pattern: "  +", options: [])
    let doubleSpaceMatches = doubleSpaceRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? []
    for match in doubleSpaceMatches {
        issueCount += 1
        corrections.append(
            SpellCheckService.SpellCheckResult.Correction(
                range: match.range,
                original: Range(match.range, in: text).map { String(text[$0]) } ?? "",
                suggestion: " ",
                type: .punctuation,
                confidence: 1.0
            )
        )
    }

    // Check for missing space after punctuation
    let punctuationRegex = try? NSRegularExpression(pattern: "([.!?,;:])([A-Z])", options: [])
    let punctuationMatches = punctuationRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? []
    for match in punctuationMatches {
        issueCount += 1
        if let range = Range(match.range, in: text) {
            let original = String(text[range])
            guard let firstChar = original.first, let lastChar = original.last else { continue }
            let suggestion = String(firstChar) + " " + String(lastChar)
            corrections.append(
                SpellCheckService.SpellCheckResult.Correction(
                    range: match.range,
                    original: original,
                    suggestion: suggestion,
                    type: .punctuation,
                    confidence: 0.9
                )
            )
        }
    }

    // Check for common grammar patterns (simplified)
    let grammarPatterns = [
        ("\\ba\\s+[aeiouAEIOU]", "an"), // "a" before vowel
        ("\\ban\\s+[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]", "a"), // "an" before consonant
    ]

    for (pattern, _) in grammarPatterns {
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            issueCount += matches.count
        }
    }

    return issueCount
}

// Custom dictionary for domain-specific terms
actor CustomDictionary {
    private var words: Set<String> = [
        // Government acquisition terms
        "FAR", "DFAR", "DFARS", "IDIQ", "QASP", "IGCE", "PWS", "SOW", "SOO",
        "LPTA", "FPDS", "SAM", "NAICS", "PSC", "CLIN", "SLIN", "FFP",
        "CPFF", "CPIF", "CPAF", "FPI", "OTA", "BAA", "RFI", "RFQ", "RFP",
        "SDVOSB", "WOSB", "HUBZone", "AbilityOne", "GSA", "SEWP", "CIO-SP3",
        "DUNS", "UEI", "CAGE", "ACO", "KO", "CO", "COR", "COTR", "PM", "TPM",

        // Technical terms
        "cybersecurity", "middleware", "microservices", "API", "APIs", "SDK",
        "DevOps", "DevSecOps", "CI/CD", "ML", "AI", "IoT", "SaaS", "PaaS",
        "IaaS", "FedRAMP", "FISMA", "NIST", "STIGs", "DISA", "DoD", "DoE",

        // Compliance terms
        "CMMC", "NIST", "ISO", "SOC", "ITAR", "EAR", "FOCI", "SF86", "JPAS",
        "DCSA", "DCAA", "DCMA", "DTIC", "DCARC", "CPSR", "TINA", "CAS",

        // Document-specific terms
        "offeror", "offerors", "awardee", "subaward", "subcontractor",
        "deliverables", "milestone", "CDRL", "DID", "TDP", "IMS", "WBS",

        // Additional government terms
        "AIKO", "CLINs", "SLINs", "PIID", "FPDS-NG", "GSAR", "AIDAR", "VAAR",
        "solicitation", "presolicitation", "synopsis", "amendment", "modification",
        "subcontracting", "teaming", "novation", "ratification", "termination",
    ]

    func contains(_ word: String) -> Bool {
        words.contains(word.uppercased()) || words.contains(word)
    }

    func add(_ word: String) {
        words.insert(word)
    }

    func remove(_ word: String) {
        words.remove(word)
    }
}
