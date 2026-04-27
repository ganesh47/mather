import Foundation

enum NumberStoryStage {
    case gravitySplit
    case sumSprint
    case bondBlast
}

struct NumberStoryStageVocabulary: Equatable {
    let title: String
    let targetReminder: String
    let instruction: String
    let leftLabel: String
    let rightLabel: String
    let accessibilityLabel: String

    static func vocabulary(for prompt: NumberStoryPrompt, stage: NumberStoryStage) -> NumberStoryStageVocabulary {
        switch stage {
        case .gravitySplit:
            return NumberStoryStageVocabulary(
                title: "Gravity Split",
                targetReminder: "\(prompt.target) \(prompt.objectNoun)",
                instruction: "Split \(prompt.target) \(prompt.objectNoun): \(prompt.leftPart) in \(prompt.leftContainer), \(prompt.rightPart) in \(prompt.rightContainer).",
                leftLabel: prompt.leftContainer.capitalized,
                rightLabel: prompt.rightContainer.capitalized,
                accessibilityLabel: "Gravity Split. Split \(prompt.target) \(prompt.objectNoun). \(prompt.leftPart) in \(prompt.leftContainer). \(prompt.rightPart) in \(prompt.rightContainer)."
            )
        case .sumSprint:
            return NumberStoryStageVocabulary(
                title: "Story Matches",
                targetReminder: "\(prompt.target) \(prompt.objectNoun)",
                instruction: "Match each story number sentence to \(prompt.target) \(prompt.objectNoun).",
                leftLabel: "Sentence",
                rightLabel: "Total",
                accessibilityLabel: "Story Matches. Match story number sentences to \(prompt.target) \(prompt.objectNoun)."
            )
        case .bondBlast:
            return NumberStoryStageVocabulary(
                title: "Bond Blast!",
                targetReminder: "\(prompt.target) \(prompt.objectNoun)",
                instruction: "Match pairs that make \(prompt.target) \(prompt.objectNoun).",
                leftLabel: "Pick",
                rightLabel: "Match",
                accessibilityLabel: "Bond Blast matching board. Match pairs that make \(prompt.target) \(prompt.objectNoun)."
            )
        }
    }

    static func fallback(stage: NumberStoryStage, target: Int) -> NumberStoryStageVocabulary {
        switch stage {
        case .gravitySplit:
            return NumberStoryStageVocabulary(
                title: "Gravity Split",
                targetReminder: "Make \(target)",
                instruction: "Use plus and minus to build the split from zero.",
                leftLabel: "Left",
                rightLabel: "Right",
                accessibilityLabel: "Balance scale. Make \(target)."
            )
        case .sumSprint:
            return NumberStoryStageVocabulary(
                title: "Sum Sprint",
                targetReminder: "Make \(target)",
                instruction: "Tap a sum sentence, then tap its total.",
                leftLabel: "Sentence",
                rightLabel: "Total",
                accessibilityLabel: "Sum Sprint. Match each sum sentence to its total."
            )
        case .bondBlast:
            return NumberStoryStageVocabulary(
                title: "Bond Blast!",
                targetReminder: "Make \(target)",
                instruction: "Match the pairs that make \(target).",
                leftLabel: "Pick",
                rightLabel: "Match",
                accessibilityLabel: "Bond Blast matching board. Make \(target)."
            )
        }
    }
}
