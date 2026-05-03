import SwiftUI
import Testing
@testable import Mather

@Suite("ResponsiveLayout")
struct ResponsiveLayoutTests {
    @MainActor @Test func settingsColumnsExpandOnRegularWidth() {
        #expect(ResponsiveLayout.settingsColumns(for: .compact).count == 1)
        #expect(ResponsiveLayout.settingsColumns(for: .regular).count == 2)
    }

    @MainActor @Test func profilePickerLayoutGetsWiderOnRegularWidth() {
        #expect(ResponsiveLayout.profileColumns(for: .compact).count == 1)
        #expect(ResponsiveLayout.profileColumns(for: .regular).count == 1)
        #expect(ResponsiveLayout.profilePickerMaxWidth(for: .regular) == 920)
        #expect(ResponsiveLayout.profilePickerMaxWidth(for: .compact) == .infinity)
    }

    @MainActor @Test func contentPaddingAndWidthsStayTabletAware() {
        #expect(ResponsiveLayout.contentPadding(for: .compact) == 24)
        #expect(ResponsiveLayout.contentPadding(for: .regular) == 48)
        #expect(ResponsiveLayout.contentMaxWidth(for: .regular) > ResponsiveLayout.contentMaxWidth(for: .compact))
        #expect(ResponsiveLayout.isWide(.regular))
        #expect(!ResponsiveLayout.isWide(.compact))
    }

    @MainActor @Test func parentSummaryUsesRegularWidthSupportingAndActionColumns() {
        #expect(ResponsiveLayout.parentSummarySupportingColumns(for: .compact).count == 1)
        #expect(ResponsiveLayout.parentSummarySupportingColumns(for: .regular).count == 2)
        #expect(ResponsiveLayout.parentActionColumns(for: .compact).count == 1)
        #expect(ResponsiveLayout.parentActionColumns(for: .regular).count == 2)
    }

    @MainActor @Test func childShellsUseAdaptiveWidthRules() {
        #expect(ResponsiveLayout.childSessionMaxWidth(for: .regular) == 940)
        #expect(ResponsiveLayout.childSessionMaxWidth(for: .compact) == CGFloat.infinity)
        #expect(ResponsiveLayout.roomQuestStationMinimumWidth(for: .compact) == 170)
        #expect(ResponsiveLayout.roomQuestStationMinimumWidth(for: .regular) == 240)
        #expect(ResponsiveLayout.roomQuestStationColumns(for: .compact).count == 1)
        #expect(ResponsiveLayout.roomQuestStationColumns(for: .regular).count == 1)
    }

    @MainActor @Test func sumSprintUsesDedicatedRegularWidthCaps() {
        #expect(ResponsiveLayout.sumSprintSessionMaxWidth(for: .compact) == CGFloat.infinity)
        #expect(ResponsiveLayout.sumSprintSessionMaxWidth(for: .regular) == 820)
        #expect(ResponsiveLayout.sumSprintSummaryMaxWidth(for: .compact) == CGFloat.infinity)
        #expect(ResponsiveLayout.sumSprintSummaryMaxWidth(for: .regular) == 980)
        #expect(ResponsiveLayout.sumSprintSummaryFactColumns(for: .compact).count == 2)
        #expect(ResponsiveLayout.sumSprintSummaryFactColumns(for: .regular).count == 2)
    }

    @MainActor @Test func memoryLayoutAdaptsBoardAndLearningSheetForTablets() {
        #expect(ResponsiveLayout.memoryBoardMaxWidth(for: .regular) == 920)
        #expect(ResponsiveLayout.memoryBoardMaxWidth(for: .compact) == CGFloat.infinity)
        #expect(ResponsiveLayout.memoryCardMinimumWidth(for: .easy) > ResponsiveLayout.memoryCardMinimumWidth(for: .hard))
        #expect(ResponsiveLayout.memoryCardAspectRatio(for: .easy) > ResponsiveLayout.memoryCardAspectRatio(for: .hard))
        #expect(ResponsiveLayout.memoryLearningSheetMaxWidth(for: .regular) == 760)
        #expect(ResponsiveLayout.memoryLearningSheetMaxWidth(for: .compact) == CGFloat.infinity)
        #expect(ResponsiveLayout.memoryLearningFactMinimumWidth(for: .regular) > ResponsiveLayout.memoryLearningFactMinimumWidth(for: .compact))
    }

    @MainActor @Test func shapeLabCompactsChromeOnPhoneSizedScreens() {
        #expect(ResponsiveLayout.shapeLabUsesCompactChrome(width: 393, height: 852))
        #expect(!ResponsiveLayout.shapeLabUsesCompactChrome(width: 768, height: 1_024))
        #expect(ResponsiveLayout.shapeLabStageChromeReserve(compact: true, isLearnStage: false) < ResponsiveLayout.shapeLabStageChromeReserve(compact: false, isLearnStage: false))
        #expect(ResponsiveLayout.shapeLabStageChromeReserve(compact: true, isLearnStage: false) < ResponsiveLayout.shapeLabStageChromeReserve(compact: true, isLearnStage: true))
    }

}
