import SwiftUI

struct ShapeDetectiveTVView: View {
    @FocusState private var focusedShape: ShapeKind?
    @FocusState private var nextFocused: Bool

    @State private var clueIndex = 0
    @State private var selectedShape: ShapeKind?
    @State private var solved = 0

    private var clue: ShapeClue { ShapeClue.clues[clueIndex % ShapeClue.clues.count] }
    private var isCorrect: Bool { selectedShape == clue.answer }

    var body: some View {
        ZStack {
            MatherTVBackdrop()

            VStack(alignment: .leading, spacing: 32) {
                header
                clueCard
                shapeChoices
                feedback
            }
            .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 90)
            .padding(.vertical, 62)
        }
        .onAppear { focusedShape = clue.choices.first }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Shape Detective")
                    .font(.system(size: 68, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("tv-shape-title")

                Text("Listen to the clue, then find the mystery shape.")
                    .font(.system(size: 29, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.76))
            }

            Spacer()

            Label("\(solved) solved", systemImage: "checkmark.seal.fill")
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.86, green: 0.67, blue: 1.0))
                .padding(.horizontal, 24)
                .padding(.vertical, 15)
                .background(.white.opacity(0.08), in: Capsule())
        }
    }

    private var clueCard: some View {
        HStack(spacing: 24) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(Color(red: 0.86, green: 0.67, blue: 1.0))
                .frame(width: 76, height: 76)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 8) {
                Text("Clue \(clueIndex + 1)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.60))
                Text(clue.text)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 30)
        .frame(width: 1680, height: 132, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.14), lineWidth: 2))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Shape clue. \(clue.text)")
    }

    private var shapeChoices: some View {
        HStack(spacing: 28) {
            ForEach(clue.choices) { shape in
                Button {
                    choose(shape)
                } label: {
                    VStack(spacing: 22) {
                        shape.artwork
                            .frame(width: 150, height: 150)
                            .foregroundStyle(shape.color)

                        Text(shape.title)
                            .font(.system(size: 27, weight: .black, design: .rounded))
                            .foregroundStyle(shapeTextColor(shape))
                    }
                    .frame(width: 390, height: 310)
                }
                .buttonStyle(.plain)
                .focused($focusedShape, equals: shape)
                .disabled(selectedShape != nil)
                .background(shapeBackground(shape), in: RoundedRectangle(cornerRadius: 30))
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(shapeStroke(shape), lineWidth: 4))
                .scaleEffect(focusedShape == shape ? 1.045 : 1)
                .accessibilityLabel(shape.title)
                .accessibilityHint("Choose \(shape.title) as the mystery shape.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var feedback: some View {
        if selectedShape != nil {
            HStack(spacing: 20) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "lightbulb.fill")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(isCorrect ? Color(red: 0.78, green: 0.94, blue: 0.66) : Color(red: 1.0, green: 0.78, blue: 0.38))

                VStack(alignment: .leading, spacing: 4) {
                    Text(isCorrect ? "Mystery solved!" : "Good investigation")
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("The answer is \(clue.answer.title.lowercased()). \(clue.fact)")
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                Button("Next clue") { nextClue() }
                    .buttonStyle(.plain)
                    .focused($nextFocused)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(nextFocused ? Color(red: 0.07, green: 0.10, blue: 0.16) : .white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 17)
                    .background(nextFocused ? .white : .white.opacity(0.12), in: Capsule())
            }
            .padding(.horizontal, 26)
            .frame(width: 1680, height: 112)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 26))
        } else {
            Label("Swipe across the shapes and press select.", systemImage: "hand.tap.fill")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .frame(height: 112)
        }
    }

    private func choose(_ shape: ShapeKind) {
        selectedShape = shape
        if shape == clue.answer { solved += 1 }
        nextFocused = true
    }

    private func nextClue() {
        clueIndex += 1
        selectedShape = nil
        nextFocused = false
        focusedShape = clue.choices.first
    }

    private func shapeTextColor(_ shape: ShapeKind) -> Color {
        focusedShape == shape ? Color(red: 0.07, green: 0.10, blue: 0.16) : .white
    }

    private func shapeBackground(_ shape: ShapeKind) -> Color {
        if selectedShape == shape && shape == clue.answer { return Color(red: 0.78, green: 0.94, blue: 0.66).opacity(0.92) }
        if selectedShape == shape { return Color(red: 1.0, green: 0.72, blue: 0.38).opacity(0.72) }
        return focusedShape == shape ? .white : .white.opacity(0.08)
    }

    private func shapeStroke(_ shape: ShapeKind) -> Color {
        if selectedShape != nil && shape == clue.answer { return Color(red: 0.78, green: 0.94, blue: 0.66) }
        return focusedShape == shape ? shape.color : .white.opacity(0.14)
    }
}

private enum ShapeKind: String, Identifiable, CaseIterable {
    case circle
    case triangle
    case square
    case rectangle

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .circle: Color(red: 0.43, green: 0.84, blue: 0.92)
        case .triangle: Color(red: 1.0, green: 0.68, blue: 0.36)
        case .square: Color(red: 0.86, green: 0.67, blue: 1.0)
        case .rectangle: Color(red: 0.72, green: 0.92, blue: 0.58)
        }
    }

    @ViewBuilder var artwork: some View {
        switch self {
        case .circle:
            Circle().fill(color)
        case .triangle:
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
        case .square:
            RoundedRectangle(cornerRadius: 4).fill(color)
        case .rectangle:
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(height: 100)
        }
    }
}

private struct ShapeClue {
    let text: String
    let answer: ShapeKind
    let choices: [ShapeKind]
    let fact: String

    static let clues: [ShapeClue] = [
        .init(text: "I have no corners and one curved edge.", answer: .circle, choices: [.circle, .triangle, .square, .rectangle], fact: "A circle rolls because its edge is curved."),
        .init(text: "I have three straight sides and three corners.", answer: .triangle, choices: [.square, .triangle, .circle, .rectangle], fact: "Every triangle has exactly three sides."),
        .init(text: "I have four equal sides and four corners.", answer: .square, choices: [.rectangle, .circle, .square, .triangle], fact: "A square’s four sides are the same length."),
        .init(text: "I have four corners and two long sides.", answer: .rectangle, choices: [.triangle, .square, .rectangle, .circle], fact: "Opposite sides of a rectangle are equal.")
    ]
}

#Preview { ShapeDetectiveTVView() }
