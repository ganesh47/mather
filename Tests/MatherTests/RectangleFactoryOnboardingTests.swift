import Testing
@testable import Mather

struct RectangleFactoryOnboardingTests {
    @Test func smartStartDimensionsStayOnScreen() {
        let dims = RectangleFactoryView.smartStartDimensions(for: 24)
        #expect(dims.width >= 1)
        #expect(dims.height >= 1)
        #expect(dims.width <= 8)
        #expect(dims.height <= 8)
    }

    @Test func smartStartDimensionsDoNotAccidentallyStartSolved() {
        let dims = RectangleFactoryView.smartStartDimensions(for: 12)
        #expect(dims.width * dims.height != 12)
    }
}
