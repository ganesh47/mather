import Testing
@testable import Mather

struct GroupedNumberRepresentationTests {
    @Test func value8UsesOnesBand() {
        let representation = GroupedNumberRepresentation(8)

        #expect(representation.band == .ones)
        #expect(representation.groups.map(\.kind) == [.one])
        #expect(representation.groups.map(\.count) == [8])
        #expect(representation.accessibilityText == "8 ones")
    }

    @Test func value14UsesTeenTenFramesBand() {
        let representation = GroupedNumberRepresentation(14)

        #expect(representation.band == .teenTenFrames)
        #expect(representation.tenFrameSlots == 2)
        #expect(representation.groups.map(\.kind) == [.tenFrame, .one])
        #expect(representation.groups.map(\.count) == [1, 4])
        #expect(representation.accessibilityText == "1 ten-frame, 4 ones")
    }

    @Test func value37UsesTensAndOnesBand() {
        let representation = GroupedNumberRepresentation(37)

        #expect(representation.band == .tensOnes)
        #expect(representation.groups.map(\.kind) == [.ten, .one])
        #expect(representation.groups.map(\.count) == [3, 7])
        #expect(representation.suggestedSteps == [10, 1])
    }

    @Test func value100UsesTenTensWithoutHundredsBand() {
        let representation = GroupedNumberRepresentation(100)

        #expect(representation.band == .tensOnes)
        #expect(representation.groups.map(\.kind) == [.ten])
        #expect(representation.groups.map(\.count) == [10])
        #expect(representation.accessibilityText == "10 tens")
    }

    @Test func value250UsesHundredsTensAndOnesBand() {
        let representation = GroupedNumberRepresentation(250)

        #expect(representation.band == .hundredsTensOnes)
        #expect(representation.groups.map(\.kind) == [.hundred, .ten])
        #expect(representation.groups.map(\.count) == [2, 5])
        #expect(representation.suggestedSteps == [100, 10, 1])
    }

    @Test func value999UsesHundredsTensAndOnesBand() {
        let representation = GroupedNumberRepresentation(999)

        #expect(representation.band == .hundredsTensOnes)
        #expect(representation.groups.map(\.kind) == [.hundred, .ten, .one])
        #expect(representation.groups.map(\.count) == [9, 9, 9])
    }

    @Test func value1000UsesSingleThousandUnit() {
        let representation = GroupedNumberRepresentation(1000)

        #expect(representation.band == .thousand)
        #expect(representation.groups.map(\.kind) == [.thousand])
        #expect(representation.groups.map(\.count) == [1])
        #expect(representation.accessibilityText == "1 thousand")
    }
}
