import SwiftUI

struct LearningQuestView: View {
    @Bindable var appModel: AppModel
    @Bindable var engine: LearningQuestEngine
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var state: LearningQuestCheckpoint { engine.checkpoint }
    @ViewBuilder
    var body: some View {
        if let message = engine.pauseMessage { pausedQuest(message: message) }
        else { playableQuest }
    }
    private func pausedQuest(message: String) -> some View {
        VStack(spacing: 24) {
            Text("Quest paused").font(.largeTitle.bold()).accessibilityIdentifier("quest-paused")
            Text(engine.requestedQuestID?.title ?? state.questID.title).font(.title2.bold())
            Text(message).font(.headline).multilineTextAlignment(.center).accessibilityIdentifier("quest-storage-message")
            QuestButton(label: "Listen", symbol: "speaker.wave.2.fill", tint: MatherTheme.softBlue) { engine.speakPrompt() }
            QuestButton(label: "Quit", symbol: "house.fill", tint: MatherTheme.accent) { appModel.engine.showHome() }
                .accessibilityIdentifier("quest-paused-quit")
        }.padding(24).frame(maxWidth: 850).frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(MatherTheme.ink).background(MatherTheme.background.ignoresSafeArea())
            .onAppear { engine.speakPrompt() }
    }
    private var playableQuest: some View {
        ScrollViewReader { scroll in
        ScrollView {
            VStack(spacing: 20) {
                header
                HStack(spacing: 8) {
                    ForEach(LearningQuestStep.allCases, id: \.self) { step in
                        Image(systemName: stepSymbol(step))
                            .font(.title2).foregroundStyle(state.step == step ? MatherTheme.accent : MatherTheme.cardSubtitle.opacity(0.55))
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .accessibilityLabel(step.title + (state.completedSteps.contains(step) ? ", explored" : ""))
                    }
                }
                Text(state.step.title).accessibilityIdentifier("quest-step").font(.title2.bold()).foregroundStyle(MatherTheme.accent)
                Text(state.prompt).font(.title3.weight(.semibold)).foregroundStyle(MatherTheme.ink).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                if state.step == .celebrate { celebration } else { taskBoard }
                if state.usesChoices && state.step != .celebrate && !(state.questID == .circuitSpark && state.step == .challenge && state.predictionMade) { choices }
                if state.supportVisible {
                    Label(state.support, systemImage: "lightbulb.fill")
                        .font(.headline).foregroundStyle(MatherTheme.ink)
                        .padding(16).frame(maxWidth: .infinity).background(MatherTheme.softBlue.opacity(0.16), in: RoundedRectangle(cornerRadius: 18))
                }
                if !state.feedback.isEmpty { Text(state.feedback).font(.headline).foregroundStyle(MatherTheme.ink).multilineTextAlignment(.center).accessibilityIdentifier("quest-feedback") }

            }
            .padding(24).frame(maxWidth: 850).frame(maxWidth: .infinity).id("quest-top")
        }
        .onChange(of: state.step) { _, _ in scroll.scrollTo("quest-top", anchor: .top) }
        .onChange(of: state.numberProbeIndex) { _, _ in scroll.scrollTo("quest-top", anchor: .top) }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
        .background(MatherTheme.background.ignoresSafeArea())
        .onAppear { engine.speakPrompt() }
    }
    private var actionBar: some View {
        HStack(spacing: 16) {
            if state.step != .celebrate && !state.accepted {
                QuestButton(label: "Help", symbol: "hand.raised.fill", tint: MatherTheme.softBlue) { engine.help() }
                    .accessibilityIdentifier("quest-help")
            }
            QuestButton(label: state.primaryLabel, symbol: state.step == .celebrate ? "checkmark.seal.fill" : "arrow.right.circle.fill", tint: MatherTheme.accent) { engine.submit() }
                .disabled(!state.canSubmit).opacity(state.canSubmit ? 1 : 0.5).accessibilityIdentifier("quest-primary")
        }.padding(.horizontal, 24).padding(.vertical, 12).background(MatherTheme.background)
            .accessibilityElement(children: .contain)
    }
    @ViewBuilder private var header: some View {
        if horizontalSizeClass == .compact {
            VStack(spacing: 12) {
                questTitle
                HStack(spacing: 16) { saveButton; listenButton }
            }
        } else {
            HStack { saveButton; Spacer(); questTitle; Spacer(); listenButton }
        }
    }
    private var questTitle: some View {
        Text("\(state.questID.emoji) \(state.questID.title)")
            .font(.title.bold()).foregroundStyle(MatherTheme.ink).multilineTextAlignment(.center).accessibilityIdentifier("learning-quest-\(state.questID.rawValue)")
    }
    private var saveButton: some View {
        QuestButton(label: "Save", symbol: "bookmark.fill", tint: MatherTheme.softBlue) { appModel.leaveLearningQuest() }
            .accessibilityIdentifier("quest-save")
    }
    private var listenButton: some View {
        QuestButton(label: "Listen", symbol: "speaker.wave.2.fill", tint: MatherTheme.softBlue) { engine.speakPrompt() }
            .accessibilityIdentifier("quest-listen")
    }
    @ViewBuilder private var taskBoard: some View {
        switch state.questID {
        case .numbers: numbersBoard
        case .shapes: shapesBoard
        case .waterCycle: waterBoard
        case .circuitSpark: circuitBoard
        case .angles: angleBoard
        case .symmetry: symmetryBoard
        }
    }
    private var numbersBoard: some View {
        VStack(spacing: 16) {
            if state.step == .learn {
                HStack(alignment: .top, spacing: 16) {
                    seedGarden(count: state.counterCount, tint: MatherTheme.warm, action: { engine.adjustCount(-1) })
                    seedGarden(count: 10-state.counterCount, tint: MatherTheme.accent, action: { engine.adjustCount(1) })
                }
                Text("\(state.counterCount) + \(10-state.counterCount) = 10").font(.largeTitle.bold()).foregroundStyle(MatherTheme.ink)
                HStack { QuestButton(label: "Move left", symbol: "arrow.left", tint: MatherTheme.warm) { engine.adjustCount(1) }.accessibilityIdentifier("quest-count-add"); QuestButton(label: "Move right", symbol: "arrow.right", tint: MatherTheme.accent) { engine.adjustCount(-1) }.accessibilityIdentifier("quest-count-remove") }
            } else {
                let fixed = state.numberKnownPart
                let total = state.numberWhole
                if state.step == .challenge {
                    Text("New task \(min((state.numberProbeIndex ?? 0) + 1, state.numberProbeCount)) of \(state.numberProbeCount)")
                        .font(.headline).foregroundStyle(MatherTheme.cardSubtitle).accessibilityIdentifier("quest-probe-progress")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(0..<total, id: \.self) { index in
                            Text(index < fixed || index < fixed + state.counterCount ? state.numberProbe.symbol : "○")
                                .font(.system(size: 34)).frame(maxWidth: .infinity, minHeight: 48)
                                .background((index < fixed ? MatherTheme.warm : MatherTheme.accent).opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }.accessibilityElement(children: .ignore).accessibilityLabel("\(fixed) packed, \(state.counterCount) added, in a whole of \(total) \(state.numberProbe.objects)")
                } else {
                    HStack(spacing: 8) {
                        ForEach(0..<total, id: \.self) { index in
                            Circle().fill(index < fixed ? MatherTheme.warm : (index < fixed + state.counterCount && state.step != .remember ? MatherTheme.accent : Color.clear))
                                .overlay(Circle().stroke(MatherTheme.accent, lineWidth: 2)).frame(maxWidth: 50).aspectRatio(1, contentMode: .fit)
                        }
                    }.padding(12).accessibilityLabel("\(fixed) filled places in a whole of \(total)")
                }
                if state.step != .remember {
                    Text("\(fixed) + \(state.counterCount) = \(fixed + state.counterCount)").font(.title.bold()).foregroundStyle(MatherTheme.ink)
                    if fixed + state.counterCount > total { Text("More than \(total). Count and compare.").font(.headline).foregroundStyle(MatherTheme.coral) }
                    Text(String(repeating: state.step == .challenge ? state.numberProbe.symbol : "🌱", count: state.counterCount)).font(.system(size: 36)).frame(minHeight: 52)
                    HStack { QuestButton(label: "One less", symbol: "minus.circle.fill", tint: MatherTheme.warm) { engine.adjustCount(-1) }.accessibilityIdentifier("quest-count-remove"); Text("\(state.counterCount)").font(.system(size: 54, weight: .bold)).frame(minWidth: 80); QuestButton(label: "One more", symbol: "plus.circle.fill", tint: MatherTheme.accent) { engine.adjustCount(1) }.accessibilityIdentifier("quest-count-add") }
                }
            }
        }.padding(20).background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 24))
    }
    private func seedGarden(count: Int, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text("\(count)").font(.largeTitle.bold()).foregroundStyle(tint)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(0..<count, id: \.self) { _ in
                        Text("🌱").font(.system(size: horizontalSizeClass == .compact ? 25 : 38))
                            .frame(maxWidth: .infinity, minHeight: horizontalSizeClass == .compact ? 38 : 60)
                            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    }
                }.frame(minHeight: 80)
            }
            .frame(maxWidth: .infinity, minHeight: 80).padding(12)
            .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 20)).contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(count == 0)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(count) seeds. Move one seed to the other garden")
    }
    @ViewBuilder private var shapesBoard: some View {
        if state.step == .play {
            GeometryReader { proxy in
                let points = cornerPositions(in: proxy.size)
                ZStack {
                    Path { path in
                        guard let first = state.selectedPoints.first else { return }
                        path.move(to: points[first]); for index in state.selectedPoints.dropFirst() { path.addLine(to: points[index]) }
                        if state.selectedPoints.count >= 3 { path.closeSubpath() }
                    }.stroke(MatherTheme.accent, lineWidth: 8)
                    ForEach(0..<5, id: \.self) { index in
                        Button { engine.togglePoint(index) } label: { Circle().fill(state.selectedPoints.contains(index) ? MatherTheme.accent : MatherTheme.softBlue).frame(width: 42, height: 42).frame(width: 80, height: 80).contentShape(Rectangle()) }
                            .position(points[index]).buttonStyle(.plain).accessibilityLabel("Corner \(index+1)").accessibilityIdentifier("quest-shape-point-\(index)")
                    }
                }
            }.frame(height: 300).padding(20).background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 24))
        } else {
            VStack(spacing: 12) {
                QuestShapePicture(kind: state.step == .challenge ? state.shapeTransferKind : state.step == .learn ? state.currentShape : "triangle")
                    .fill(MatherTheme.coral).frame(width: 170, height: 170).rotationEffect(.degrees(Double(state.step == .challenge && state.questID == .shapes ? state.shapeTransferRotation : state.angleDegrees)))
                    .padding(38).accessibilityLabel(state.step == .challenge ? "A \(state.shapeTransferKind == "triangle" ? "sign" : "door") outline turned to a new direction" : state.step == .learn ? "\(state.content.shapeName(state.currentShape)), turned" : "Outline with three straight sides and three corners, turned")
                if state.step == .learn {
                    Text(state.content.shapeFact(state.currentShape)).font(.headline).foregroundStyle(MatherTheme.ink).padding(.horizontal)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                        ForEach(["circle", "triangle", "square", "rectangle"], id: \.self) { shape in
                            Button { engine.selectShape(shape) } label: {
                                VStack { QuestShapePicture(kind: shape).fill(MatherTheme.coral).frame(width: 50, height: 50); Text(state.content.shapeName(shape)).font(.caption.bold()) }
                                    .frame(maxWidth: .infinity, minHeight: 90).background(MatherTheme.softBlue.opacity(state.exploredShapes.contains(shape) ? 0.4 : 0.12), in: RoundedRectangle(cornerRadius: 16))
                            }.buttonStyle(.plain).accessibilityIdentifier("quest-shape-select-\(shape)")
                        }
                    }.padding(.horizontal)
                    QuestButton(label: "Turn", symbol: "rotate.right", tint: MatherTheme.accent) { engine.turnShape() }.accessibilityIdentifier("quest-shape-turn")
                }
            }.frame(maxWidth: .infinity).background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 24))
        }
    }
    private var waterBoard: some View {
        VStack(spacing: 16) {
            if state.step == .challenge {
                QuestColdCupPicture(drops: state.accepted ? "outside" : "none", vessel: state.waterVessel)
                    .frame(width: 160, height: 180)
                    .accessibilityLabel(state.accepted ? "Liquid drops appeared outside the cold \(state.waterVessel)" : "A cold \(state.waterVessel) in warm moist air; predict before observing")
            } else {
            HStack(spacing: 20) {
                Text(state.waterState == 0 ? "☀️" : state.waterState == 1 ? "⬆️" : "☁️💧").font(.system(size: 80)).accessibilityLabel(state.waterState == 0 ? "Sun above liquid water" : state.waterState == 1 ? "Arrows represent invisible water vapor" : "Tiny liquid drops in a cloud")
                if state.step == .challenge { Text("🥤💧").font(.system(size: 80)).accessibilityLabel("Cold cup in warm moist air") }
            }
            Capsule().fill(MatherTheme.softBlue).frame(height: 44).overlay(Text("💧💧💧").font(.title))
            }
            if state.step == .learn {
                HStack {
                    QuestButton(label: "Warm pond", symbol: "sun.max.fill", tint: MatherTheme.warm) { engine.warmWater() }.accessibilityIdentifier("quest-water-warm")
                    QuestButton(label: "Cool air", symbol: "snowflake", tint: MatherTheme.softBlue) { engine.coolWater() }.accessibilityIdentifier("quest-water-cool").disabled(state.waterState != 1)
                }
            }
        }.padding(24).frame(maxWidth: .infinity).background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 24))
    }
    private var circuitBoard: some View {
        VStack(spacing: 16) {
            QuestCircuitPicture(connected: state.wireConnected, closed: state.switchClosed, secondClosed: state.step == .challenge ? state.secondSwitchClosed : nil, concealLight: state.step == .challenge && !state.predictionMade)
                .frame(height: 230).accessibilityElement(children: .ignore)
                .accessibilityLabel(state.circuitAccessibilityDescription).accessibilityIdentifier("quest-circuit-state")
            if state.step == .learn || state.step == .play || (state.step == .challenge && state.predictionMade) {
                HStack {
                    if state.step == .play { QuestButton(label: state.wireConnected ? "Open wire" : "Join wire", symbol: "link", tint: MatherTheme.softBlue) { engine.repairWire() }.accessibilityIdentifier("quest-wire-repair") }
                    QuestButton(label: "Switch", symbol: "switch.2", tint: MatherTheme.accent) { engine.toggleSwitch() }.accessibilityIdentifier("quest-switch-first")
                    if state.step == .challenge { QuestButton(label: "Second switch", symbol: "switch.2", tint: MatherTheme.accent) { engine.toggleSwitch(second: true) }.accessibilityIdentifier("quest-switch-second") }
                }
            }
        }.padding(24).background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 24))
    }
    private var angleBoard: some View {
        VStack(spacing: 12) {
            ZStack {
                QuestAnglePicture(degrees: state.step == .challenge ? 120 : 90).stroke(MatherTheme.softBlue.opacity(0.4), style: StrokeStyle(lineWidth: 12, dash: [10,8]))
                QuestAnglePicture(degrees: state.angleDegrees).stroke(MatherTheme.coral, lineWidth: 8)
            }.frame(width: 250, height: 230).accessibilityLabel("Gate open \(state.angleDegrees) degrees")
            if state.step != .remember {
                HStack { QuestButton(label: "Close a little", symbol: "minus.circle.fill", tint: MatherTheme.warm) { engine.changeAngle(-15) }.accessibilityIdentifier("quest-angle-remove"); QuestButton(label: "Open a little", symbol: "plus.circle.fill", tint: MatherTheme.accent) { engine.changeAngle(15) }.accessibilityIdentifier("quest-angle-add") }
            }
        }.padding(24).frame(maxWidth: .infinity).background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 24))
    }
    private var symmetryBoard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack(spacing: 8) { ForEach(0..<3, id: \.self) { index in Text(mirrorTarget[index] ? "🌸" : "🍃").font(.system(size: 44)).frame(width: 80, height: 80).background(MatherTheme.coral.opacity(0.15), in: RoundedRectangle(cornerRadius: 18)) } }
                Rectangle().fill(MatherTheme.ink.opacity(0.35)).frame(width: 3)
                VStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Button { engine.toggleMirrorCell(index) } label: { Text(state.mirrorCells[index] ? "🌸" : "🍃").font(.system(size: 44)).frame(width: 80, height: 80).background(MatherTheme.softBlue.opacity(0.2), in: RoundedRectangle(cornerRadius: 18)) }
                            .buttonStyle(.plain).disabled(state.step == .remember || state.step == .learn).accessibilityLabel("Change wing patch \(index+1)").accessibilityIdentifier("quest-mirror-patch-\(index)")
                    }
                }.opacity(state.folded ? 0.35 : 1).offset(x: state.folded ? -99 : 0)
            }.frame(height: 270)
            if state.step != .remember { QuestButton(label: state.folded ? "Unfold" : "Fold", symbol: "rectangle.compress.vertical", tint: MatherTheme.accent) { engine.fold() }.accessibilityIdentifier("quest-fold") }
        }.padding(24).frame(maxWidth: .infinity).background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 24))
    }
    private var mirrorTarget: [Bool] { state.step == .challenge ? [false,true,false] : [true,false,true] }
    private var choices: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
            ForEach(state.choices) { choice in
                Button { engine.choose(choice.id) } label: {
                    VStack(spacing: 10) {
                        choicePicture(choice).frame(height: 92)
                        Text(choice.label).font(.headline).foregroundStyle(MatherTheme.ink).multilineTextAlignment(.center)
                    }.padding(16).frame(maxWidth: .infinity, minHeight: 150)
                        .background(state.selectedChoice == choice.id ? MatherTheme.accent.opacity(0.18) : MatherTheme.card, in: RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(state.selectedChoice == choice.id ? MatherTheme.accent : Color.clear, lineWidth: 4))
                }.buttonStyle(.plain).disabled(state.accepted).accessibilityLabel(choiceAccessibilityLabel(choice)).accessibilityIdentifier("quest-choice-\(choice.id)")
            }
        }
    }
    private func choiceAccessibilityLabel(_ choice: LearningQuestChoice) -> String {
        switch state.questID {
        case .shapes:
            let description = choice.symbol == "circle" ? "round outline, no corners" : choice.symbol == "triangle" ? "three sides and three corners, turned" : choice.symbol == "square" ? "four equal sides and four square corners" : "four square corners, two longer and two shorter sides, turned"
            return "\(choice.label). \(description)"
        case .angles: return "\(choice.label). Turn of \(choice.id) degrees"
        case .symmetry: return "\(choice.label). " + (choice.id == "match" ? "Flower opposite flower, leaf opposite leaf" : "Flower opposite leaf, leaf opposite flower")
        case .circuitSpark where state.step == .remember: return "\(choice.label). " + (choice.id == "closed" ? "Joined path from battery through bulb and back" : "One open switch in the path")
        default: return choice.label
        }
    }
    @ViewBuilder private func choicePicture(_ choice: LearningQuestChoice) -> some View {
        if state.questID == .waterCycle && state.step == .challenge { QuestColdCupPicture(drops: choice.id, vessel: state.waterVessel).frame(width: 95, height: 92) }
        else if state.questID == .shapes { QuestShapePicture(kind: choice.symbol).fill(MatherTheme.coral).frame(width: 85, height: 85).rotationEffect(.degrees(choice.id == "triangle" ? 70 : choice.id == "rectangle" ? 35 : 0)) }
        else if state.questID == .angles { QuestAnglePicture(degrees: Int(choice.id) ?? 90).stroke(MatherTheme.coral, lineWidth: 6).frame(width: 95, height: 90) }
        else if state.questID == .circuitSpark && state.step == .remember { QuestCircuitPicture(connected: true, closed: choice.id == "closed", secondClosed: nil) }
        else if state.questID == .symmetry { Text(choice.id == "match" ? "🌸 | 🌸\n🍃 | 🍃" : "🌸 | 🍃\n🍃 | 🌸").font(.title2.bold()).foregroundStyle(MatherTheme.coral) }
        else { Text(choice.symbol).font(.system(size: 54, weight: .bold)).foregroundStyle(MatherTheme.accent) }
    }
    private var celebration: some View {
        VStack(spacing: 16) {
            Text("🌟🎉🌟").font(.system(size: 68)).accessibilityLabel("Quest celebration")
            Text("You kept trying!").font(.largeTitle.bold()).foregroundStyle(MatherTheme.accent)
            Text(state.questID.offscreenPrompt).font(.title3).foregroundStyle(MatherTheme.ink).multilineTextAlignment(.center)
        }.padding(32).frame(maxWidth: .infinity).background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 24))
    }
    private func stepSymbol(_ step: LearningQuestStep) -> String { switch step { case .learn: "hand.draw.fill"; case .remember: "brain.head.profile"; case .play: "gamecontroller.fill"; case .challenge: "sparkles"; case .celebrate: "star.fill" } }
    private func cornerPositions(in size: CGSize) -> [CGPoint] { [.init(x:45,y:45),.init(x:size.width-45,y:45),.init(x:size.width/2,y:size.height/2),.init(x:45,y:size.height-45),.init(x:size.width-45,y:size.height-45)] }
}

private struct QuestButton: View {
    let label: String
    let symbol: String
    let tint: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(label, systemImage: symbol).font(.headline.bold()).foregroundStyle(MatherTheme.ink)
                .frame(minWidth: 80, maxWidth: .infinity, minHeight: 80).padding(.horizontal, 8)
                .background(tint.opacity(0.2), in: RoundedRectangle(cornerRadius: 18)).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(label)
    }
}

private struct QuestShapePicture: Shape {
    let kind: String
    func path(in rect: CGRect) -> Path {
        switch kind {
        case "circle": return Path(ellipseIn: rect)
        case "square": return Path(rect)
        case "rectangle": return Path(CGRect(x:rect.minX,y:rect.midY-rect.height*0.28,width:rect.width,height:rect.height*0.56))
        default:
            return Path { $0.move(to:.init(x:rect.midX,y:rect.minY));$0.addLine(to:.init(x:rect.maxX,y:rect.maxY));$0.addLine(to:.init(x:rect.minX,y:rect.maxY));$0.closeSubpath() }
        }
    }
}
private struct QuestAnglePicture: Shape {
    let degrees: Int
    func path(in rect: CGRect) -> Path {
        let pivot = CGPoint(x: rect.width / 2, y: rect.height * 0.8)
        let radius: CGFloat = min(rect.width / 2 - 8, rect.height * 0.7)
        let angle: Double = Double(degrees) * Double.pi / 180
        let start = CGPoint(x: pivot.x + radius, y: pivot.y)
        let end = CGPoint(x: pivot.x + radius * CGFloat(cos(angle)),
                          y: pivot.y - radius * CGFloat(sin(angle)))
        return Path { path in
            path.move(to: start)
            path.addLine(to: pivot)
            path.addLine(to: end)
        }
    }
}
private struct QuestCircuitPicture: View {
    let connected: Bool
    let closed: Bool
    let secondClosed: Bool?
    var concealLight = false
    private var lit: Bool { connected && closed && (secondClosed ?? true) }
    var body: some View {
        GeometryReader { proxy in
            let w=proxy.size.width, h=proxy.size.height
            ZStack {
                Path { p in p.move(to:.init(x:w*0.2,y:h*0.8));p.addLine(to:.init(x:w*0.2,y:h*0.2));p.addLine(to:.init(x:w*0.8,y:h*0.2));p.addLine(to:.init(x:w*0.8,y:h*0.8));p.addLine(to:.init(x:w*0.6,y:h*0.8)); if connected { p.addLine(to:.init(x:w*0.2,y:h*0.8)) } }
                    .stroke(lit ? MatherTheme.warm : MatherTheme.ink.opacity(0.5),lineWidth:7)
                Text("🔋").font(.system(size:min(h*0.25,48))).position(x:w*0.2,y:h*0.5)
                Text(concealLight ? "?" : lit ? "💡" : "⚫").font(.system(size:min(h*0.26,58))).position(x:w*0.8,y:h*0.5)
                switchPicture(isClosed:closed).position(x:w*0.5,y:h*0.2)
                if let secondClosed { switchPicture(isClosed:secondClosed).position(x:w*0.5,y:h*0.8) }
                if !connected { Text("gap").font(.headline).foregroundStyle(MatherTheme.coral).position(x:w*0.4,y:h*0.8) }
            }
        }
    }
    private func switchPicture(isClosed:Bool) -> some View { Text(isClosed ? "━━" : "╱  ━").font(.system(size:26,weight:.bold)).foregroundStyle(MatherTheme.ink).padding(4).background(MatherTheme.card) }
}


private struct QuestColdCupPicture: View {
    let drops: String
    var vessel = "cup"
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            ZStack {
                Path { path in
                    if vessel == "bottle" {
                        path.move(to: CGPoint(x: w*0.42, y: h*0.13)); path.addLine(to: CGPoint(x: w*0.42, y: h*0.3)); path.addLine(to: CGPoint(x: w*0.27, y: h*0.4)); path.addLine(to: CGPoint(x: w*0.27, y: h*0.85)); path.addLine(to: CGPoint(x: w*0.73, y: h*0.85)); path.addLine(to: CGPoint(x: w*0.73, y: h*0.4)); path.addLine(to: CGPoint(x: w*0.58, y: h*0.3)); path.addLine(to: CGPoint(x: w*0.58, y: h*0.13)); path.closeSubpath(); return
                    }
                    path.move(to: CGPoint(x: w*0.27, y: h*0.22)); path.addLine(to: CGPoint(x: w*0.34, y: h*0.85)); path.addLine(to: CGPoint(x: w*0.66, y: h*0.85)); path.addLine(to: CGPoint(x: w*0.73, y: h*0.22))
                }.fill(MatherTheme.softBlue.opacity(0.18))
                Path { path in
                    if vessel == "bottle" {
                        path.move(to: CGPoint(x: w*0.42, y: h*0.13)); path.addLine(to: CGPoint(x: w*0.42, y: h*0.3)); path.addLine(to: CGPoint(x: w*0.27, y: h*0.4)); path.addLine(to: CGPoint(x: w*0.27, y: h*0.85)); path.addLine(to: CGPoint(x: w*0.73, y: h*0.85)); path.addLine(to: CGPoint(x: w*0.73, y: h*0.4)); path.addLine(to: CGPoint(x: w*0.58, y: h*0.3)); path.addLine(to: CGPoint(x: w*0.58, y: h*0.13)); path.closeSubpath(); return
                    }
                    path.move(to: CGPoint(x: w*0.27, y: h*0.22)); path.addLine(to: CGPoint(x: w*0.34, y: h*0.85)); path.addLine(to: CGPoint(x: w*0.66, y: h*0.85)); path.addLine(to: CGPoint(x: w*0.73, y: h*0.22))
                }.stroke(MatherTheme.ink, lineWidth: 4)
                Image(systemName: "snowflake").font(.system(size: h*0.2)).foregroundStyle(MatherTheme.softBlue).position(x: w*0.5, y: h*0.17)
                if drops != "none" {
                    ForEach(0..<3, id: \.self) { index in
                        let verticalFraction: CGFloat = 0.42 + CGFloat(index) * 0.15
                        Image(systemName: "drop.fill").font(.system(size: h*0.13)).foregroundStyle(MatherTheme.accent)
                            .position(x: drops == "outside" ? w*0.83 : w*0.5, y: h * verticalFraction)
                    }
                }
            }
        }.accessibilityLabel(drops == "outside" ? "Cold \(vessel) with drops outside" : drops == "inside" ? "Cold \(vessel) with drops inside" : "Cold \(vessel) without drops")
    }
}
