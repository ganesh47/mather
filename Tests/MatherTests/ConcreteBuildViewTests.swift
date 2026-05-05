import Testing
@testable import Mather

struct ConcreteBuildViewTests {
    @Test func tapOnNextWarmCounterAddsOne() {
        let action = ConcreteBuildView.tapAction(for: 2, target: 8, warmCount: 2, accentCount: 0)
        #expect(action?.delta == 1)
        #expect(action?.group == .warm)
    }

    @Test func tapOnLastFilledWarmCounterRemovesOne() {
        let action = ConcreteBuildView.tapAction(for: 2, target: 8, warmCount: 3, accentCount: 0)
        #expect(action?.delta == -1)
        #expect(action?.group == .warm)
    }

    @Test func tappingFurtherAlongWarmRowDoesNothing() {
        let action = ConcreteBuildView.tapAction(for: 4, target: 8, warmCount: 2, accentCount: 0)
        #expect(action == nil)
    }

    @Test func accentCountersStayLockedUntilWarmRowIsFull() {
        let action = ConcreteBuildView.tapAction(for: 10, target: 12, warmCount: 9, accentCount: 0)
        #expect(action == nil)
    }

    @Test func tapOnNextAccentCounterAddsOneAfterUnlock() {
        let action = ConcreteBuildView.tapAction(for: 11, target: 12, warmCount: 10, accentCount: 1)
        #expect(action?.delta == 1)
        #expect(action?.group == .accent)
    }
}


extension ConcreteBuildViewTests {
    @Test func smallTargetsKeepAFullTenFrameAvailableWithoutAccentGroup() {
        #expect(ConcreteBuildView.tapAction(for: 5, target: 6, warmCount: 5, accentCount: 0)?.group == .warm)
        #expect(ConcreteBuildView.tapAction(for: 9, target: 6, warmCount: 5, accentCount: 0) == nil)
    }
}
