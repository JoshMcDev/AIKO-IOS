import SwiftUI
import ComposableArchitecture

// Question Display Component
struct QuestionView: View {
    let question: DocumentExecutionFeature.InformationQuestion
    let index: Int
    let total: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Question \(index + 1) of \(total)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(question.question)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            if question.isRequired {
                Text("* Required")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.aikoSecondary.opacity(0.5))
        )
    }
}

// Answer Field Component
struct AnswerFieldView: View {
    let question: DocumentExecutionFeature.InformationQuestion
    @Binding var answer: String
    @FocusState var isTextFieldFocused: Bool
    
    @ViewBuilder
    var body: some View {
        switch question.fieldType {
            case .text:
                TextField("", text: $answer, prompt: Text("...").foregroundColor(.gray))
                    .textFieldStyle(CustomTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .onAppear {
                        isTextFieldFocused = true
                    }
                
            case .number:
                TextField("", text: $answer, prompt: Text("...").foregroundColor(.gray))
                    .textFieldStyle(CustomTextFieldStyle())
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .focused($isTextFieldFocused)
                    .onAppear {
                        isTextFieldFocused = true
                    }
                
            case .multilineText:
                TextEditor(text: $answer)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(Color.white.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundColor(.white)
                    .focused($isTextFieldFocused)
                    .onAppear {
                        isTextFieldFocused = true
                    }
                
            case .date:
                TextField("", text: $answer, prompt: Text("...").foregroundColor(.gray))
                    .textFieldStyle(CustomTextFieldStyle())
                    .focused($isTextFieldFocused)
                
            case .selection(let options):
                SelectionFieldView(options: options, selectedOption: $answer)
        }
    }
}

// Selection Field Component
struct SelectionFieldView: View {
    let options: [String]
    @Binding var selectedOption: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selectedOption = option
                }) {
                    HStack {
                        Text(option)
                            .foregroundColor(.white)
                        Spacer()
                        if selectedOption == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(selectedOption == option ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(selectedOption == option ? Color.blue : Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }
}

// Progress Indicator Component
struct ProgressIndicatorView: View {
    let currentIndex: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index <= currentIndex ? Color.blue : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom)
    }
}