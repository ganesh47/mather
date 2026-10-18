import SwiftUI
import AVFoundation
import UIKit

@MainActor
struct WorldQuestTVView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var engine: WorldQuestEngine?
    @State private var geometry: WorldMapGeometry?
    @State private var navigation: WorldQuestNavigation?
    @State private var loadFailed = false
    @State private var progress = WorldQuestProgressStore()
    @State private var narration = TVNarrationController()
    @State private var selectedPack: WorldQuestPack = .starter
    @State private var selectedMode: WorldQuestMode = .practice
    @State private var mapNavigationActive = false
    @State private var focusedCountryID: String?
    @State private var zoom: WorldQuestZoom = .world
    @State private var exploreDetail: String?
    @State private var showInformation = false
    @State private var promptTask: Task<Void, Never>?
    @State private var waitingForVoiceOverStart = false
    @FocusState private var focusedControl: Control?

    private enum Control: Hashable {
        case map, world, region, close, hint, reveal, resume, next, start, replay, info
        case pack(WorldQuestPack), mode(WorldQuestMode)
    }

    var body: some View {
        ZStack {
            MatherTVBackdrop()
            if let engine, let geometry {
                VStack(alignment: .leading, spacing: 18) {
                    header(engine)
                        .layoutPriority(1)
                    if engine.phase == .setup { setup(engine) }
                    else if engine.phase == .completed { results(engine) }
                    else { game(engine, geometry: geometry) }
                }
                .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 90)
                .padding(.top, 85)
                .padding(.bottom, 36)
            } else if loadFailed {
                Text("The world map could not be opened. Return to All games and try again.")
                    .font(.title)
                    .accessibilityIdentifier("world-quest-load-error")
            } else {
                ProgressView("Opening the world…")
            }
        }
        .task { await loadContent() }
        .task {
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                engine?.tick()
            }
        }
        .task {
            for await notification in NotificationCenter.default.notifications(named: AVAudioSession.interruptionNotification) {
                let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
                if type == AVAudioSession.InterruptionType.began.rawValue { suspendForInterruption() }
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: UIAccessibility.voiceOverStatusDidChangeNotification) {
                if engine?.phase == .answering {
                    if UIAccessibility.isVoiceOverRunning { repeatGuidance() }
                    else {
                        waitingForVoiceOverStart = false
                        repeatGuidance()
                    }
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { suspendForInterruption() }
            else if engine?.needsResume == true { focusedControl = .resume }
            else if engine?.phase == .feedback { focusedControl = .next }
            else if engine?.phase == .exploring {
                mapNavigationActive = true
                focusedControl = .map
            }
            else if engine?.phase == .completed { focusedControl = .replay }
            else if engine?.phase == .setup { focusedControl = .start }
        }
        .onChange(of: engine?.phase) { _, phase in phaseChanged(phase) }
        .onChange(of: engine?.questionIndex) { _, _ in presentQuestion() }
        .onChange(of: focusedControl) { _, control in
            if let control, control != .map { narration.focus(controlGuidance(control)) }
            if control == .map { mapNavigationActive = true }
            else if mapNavigationActive, control == nil {
                Task { @MainActor in
                    await Task.yield()
                    if mapNavigationActive { focusedControl = .map }
                }
            }
        }
        .onChange(of: focusedCountryID) { _, _ in
            if engine?.phase == .exploring, let country = focusedCountry {
                exploreDetail = nil
                narration.focus("\(country.name). \(country.continent.rawValue).")
            }
        }
        .onPlayPauseCommand { repeatGuidance() }
        .onDisappear {
            promptTask?.cancel()
            narration.stop()
            engine?.suspend(.interruption)
        }
        .sheet(isPresented: $showInformation) { information }
    }

    private var focusedCountry: WorldQuestCountry? { focusedCountryID.flatMap { engine?.catalog.country($0) } }

    private func header(_ engine: WorldQuestEngine) -> some View {
        let earned = Set(engine.answers.filter { $0.outcome != .revealed }.map(\.countryID))
        let stampCount = progress.progress.countryStamps.union(earned).count
        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("World Quest").font(.system(size: 48, weight: .bold, design: .rounded))
                Text(engine.phase == .setup ? "A little explorer. A whole world to discover." : "\(engine.pack.rawValue) · \(engine.mode.rawValue)")
                    .font(.system(size: 23, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
            Label("\(stampCount) / 195", systemImage: "globe.europe.africa.fill")
                .font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(.mint)
                .accessibilityLabel("Passport: \(stampCount) countries found")
        }
        .foregroundStyle(.white)
    }

    private func setup(_ engine: WorldQuestEngine) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Choose your adventure").font(.system(size: 30, weight: .bold, design: .rounded))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                ForEach(WorldQuestPack.allCases) { pack in
                    Button {
                        selectedPack = pack
                        narration.announce("\(pack.rawValue). \(engine.catalog.countries(in: pack).count) countries.")
                    } label: {
                        VStack(spacing: 8) {
                            Text(pack.rawValue).font(.system(size: 26, weight: .bold, design: .rounded))
                            Text("\(engine.catalog.countries(in: pack).count) countries").font(.system(size: 20))
                        }
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(selectedPack == pack ? Color.teal.opacity(0.7) : .white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.card)
                    .focused($focusedControl, equals: .pack(pack))
                    .accessibilityAddTraits(selectedPack == pack ? .isSelected : [])
                    .accessibilityIdentifier("world-quest-pack-\(pack.id)")
                }
            }
            HStack(spacing: 22) {
                ForEach(WorldQuestMode.allCases) { mode in
                    Button {
                        selectedMode = mode
                        narration.announce("\(mode.rawValue). \(mode.detail).")
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(mode.rawValue).font(.system(size: 30, weight: .bold, design: .rounded))
                            Text(mode.detail).font(.system(size: 20)).lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
                        .padding(.horizontal, 22)
                        .background(selectedMode == mode ? Color.teal.opacity(0.7) : .white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.card)
                    .focused($focusedControl, equals: .mode(mode))
                    .accessibilityAddTraits(selectedMode == mode ? .isSelected : [])
                    .accessibilityIdentifier("world-quest-mode-\(mode.id)")
                }
            }
            // The rightmost mode has no geometric neighbor below it.
            .onMoveCommand { direction in
                if direction == .down { focusedControl = .start }
            }
            HStack(spacing: 24) {
                Button("Start exploring", systemImage: "globe") { start(engine) }
                    .focused($focusedControl, equals: .start)
                    .accessibilityIdentifier("world-quest-start")
                Button("Map information", systemImage: "info.circle") { showInformation = true }
                    .focused($focusedControl, equals: .info)
            }
            .padding(.top, 12)
            Text("Swipe to move · Select to choose · Play/Pause to hear again")
                .font(.system(size: 22)).foregroundStyle(.white.opacity(0.7))
        }
        .foregroundStyle(.white)
        .padding(.top, 14)
    }

    private func game(_ engine: WorldQuestEngine, geometry: WorldMapGeometry) -> some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(questionTitle(engine))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .accessibilityIdentifier("world-quest-prompt")
                    Text(statusText(engine)).font(.system(size: 23, weight: .medium)).foregroundStyle(.white.opacity(0.8))
                        .accessibilityIdentifier("world-quest-feedback")
                }
                Spacer()
                if engine.phase == .feedback, engine.answers.last?.outcome != .revealed {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.yellow)
                        .symbolEffect(.bounce, value: reduceMotion ? 0 : engine.answers.count)
                        .accessibilityHidden(true)
                }
                if engine.mode == .timed {
                    Label("\(Int(ceil(engine.remainingSeconds)))s", systemImage: "timer")
                        .font(.system(size: 35, weight: .bold, design: .monospaced))
                        .foregroundStyle(engine.remainingSeconds <= 5 ? .orange : .mint)
                        .accessibilityIdentifier("world-quest-timer")
                }
                if engine.mode != .explore {
                    Text("\(engine.questionIndex + 1) / \(engine.questions.count)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                }
            }
            toolbar(engine)
                .disabled(mapNavigationActive)
            Button { selectMap(engine) } label: {
                WorldQuestMapView(geometry: geometry, selectableIDs: Set(engine.selectableCountries.map(\.id)),
                                  focusedID: focusedCountryID,
                                  revealedID: engine.phase == .feedback ? engine.target?.id : nil,
                                  hintContinent: engine.hintContinent,
                                  viewport: geometry.viewport(for: zoom, focusedID: focusedCountryID, pack: engine.pack))
                    .equatable()
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(focusedControl == .map ? .yellow.opacity(0.8) : .clear, lineWidth: 3))
            }
            .buttonStyle(WorldQuestMapButtonStyle())
            .focusEffectDisabled()
            .focused($focusedControl, equals: .map)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(mapAccessibilityLabel(engine))
            .accessibilityValue(engine.isSuspended ? "Listening or paused" : "Ready")
            .accessibilityHint(engine.phase == .feedback ? "Press Select to continue" : "Directional presses move between country locations. Select chooses this location. Up at the northern edge reaches map controls.")
            .accessibilityIdentifier("world-quest-map")
            .onMoveCommand { direction in move(direction, engine: engine) }
            Text("Yellow: your location · Green: answer · Small dots mark small countries")
                .font(.system(size: 18)).foregroundStyle(.white.opacity(0.7))
                .accessibilityHidden(true)
        }
        .foregroundStyle(.white)
    }

    private func toolbar(_ engine: WorldQuestEngine) -> some View {
        HStack(spacing: 18) {
            ForEach(WorldQuestZoom.allCases, id: \.self) { level in
                Button {
                    zoom = level
                    mapNavigationActive = true
                    focusedControl = .map
                    narration.announce("\(level.rawValue) view.")
                } label: {
                    Text(level.rawValue).font(.system(size: 22, weight: .bold))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                }
                .focused($focusedControl, equals: control(for: level))
                .accessibilityAddTraits(zoom == level ? .isSelected : [])
                .accessibilityIdentifier("world-quest-zoom-\(level.rawValue)")
            }
            Spacer(minLength: 0)
            if engine.needsResume || waitingForVoiceOverStart {
                Button(engine.needsResume ? "Resume" : "Start country") {
                    engine.resume(.interruption)
                    waitingForVoiceOverStart = false
                    mapNavigationActive = true
                    focusedControl = .map
                    if UIAccessibility.isVoiceOverRunning { engine.resume(.narration) }
                    else { speakPausingClock(engine.prompt) }
                }
                .focused($focusedControl, equals: .resume)
                .accessibilityLabel(engine.needsResume ? "Resume. \(engine.prompt)" : "\(engine.prompt) Start country when you are ready.")
                .accessibilityIdentifier("world-quest-resume")
            } else if engine.phase == .feedback {
                Button(engine.questionIndex + 1 == engine.questions.count ? "See passport" : "Next country") { engine.advance() }
                    .focused($focusedControl, equals: .next)
                    .accessibilityIdentifier("world-quest-next")
            } else if engine.phase == .answering {
                Button("Hint") {
                    engine.hint()
                    if let continent = engine.hintContinent { speakPausingClock("Look in \(continent.rawValue).") }
                }
                .focused($focusedControl, equals: .hint)
                .accessibilityIdentifier("world-quest-hint")
                Button("Reveal") { engine.reveal() }
                    .focused($focusedControl, equals: .reveal)
                    .accessibilityIdentifier("world-quest-reveal")
            }
        }
        .onMoveCommand { direction in
            if direction == .down, !mapNavigationActive {
                mapNavigationActive = true
                focusedControl = .map
            }
        }
    }

    private func results(_ engine: WorldQuestEngine) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Your world is growing!").font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.mint)
            if let session = engine.completion {
                HStack(spacing: 36) {
                    resultMetric("Found independently", value: "\(session.independentCount)")
                    resultMetric("Found with help", value: "\(session.assistedCount)")
                    resultMetric("Places discovered", value: "\(session.revealedCount)")
                }
                if session.mode == .timed {
                    Text("First try: \(session.firstTryCount) of \(session.answers.count)")
                    if let mean = session.meanSuccessfulSeconds {
                        Text("Average finding time: \(mean.formatted(.number.precision(.fractionLength(1)))) seconds")
                    }
                }
                Text("\(progress.progress.countryStamps.count) country stamps in your passport")
                    .accessibilityIdentifier("world-quest-passport")
            }
            HStack(spacing: 26) {
                Button("Another adventure") {
                    engine.returnToSetup()
                    focusedControl = .start
                    narration.presentPrompt("Choose a pack and a way to play, then start exploring.")
                }
                .focused($focusedControl, equals: .replay)
                .accessibilityIdentifier("world-quest-replay")
                Button("Map information") { showInformation = true }
            }
        }
        .font(.system(size: 28, weight: .medium, design: .rounded))
        .foregroundStyle(.white)
        .padding(.top, 45)
    }

    private func resultMetric(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(value).font(.system(size: 70, weight: .bold, design: .rounded)).foregroundStyle(.mint)
            Text(label).font(.system(size: 25, weight: .semibold, design: .rounded))
        }
        .padding(28).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
    }

    private var information: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("About this map").font(.largeTitle.bold())
            Text("Made with Natural Earth · Public domain · Source tag v5.1.2")
            Text("Boundary viewpoint: India. Borders follow this source’s India viewpoint; viewpoints differ in disputed areas. This is an educational map, not survey data.")
            Text("195 quiz countries: 193 UN members, Palestine, and Vatican City for the Holy See. Other territories appear for geographic context. Small dots indicate locations, not country size.")
            Text("Your passport is saved only on this Apple TV. Stamps celebrate exploration, not mastery.")
            Button("Back to adventure") { showInformation = false }
        }
        .font(.system(size: 28)).padding(80)
    }

    private func loadContent() async {
        guard engine == nil, !loadFailed else { return }
        do {
            let catalog = try await Task.detached(priority: .userInitiated) { try CountryCatalog.load() }.value
            guard !Task.isCancelled else { return }
            geometry = WorldMapGeometry(catalog: catalog)
            engine = WorldQuestEngine(catalog: catalog)
            focusedControl = .start
            narration.presentPrompt("Welcome to World Quest. Choose countries and a way to play, then start exploring. Practice has no timer. Timed gives you twenty seconds for each country.")
        } catch {
            loadFailed = true
            narration.presentPrompt("The map could not be opened. Press Menu to return to all games.")
        }
    }

    private func start(_ engine: WorldQuestEngine) {
        exploreDetail = nil
        zoom = .world
        let navigation = WorldQuestNavigation(countries: engine.catalog.countries(in: selectedPack), aspectRatio: engine.catalog.aspectRatio)
        self.navigation = navigation
        focusedCountryID = navigation.initialID
        let seed = UserDefaults.standard.object(forKey: "worldQuest.seed") == nil ? nil : UserDefaults.standard.integer(forKey: "worldQuest.seed")
        engine.start(pack: selectedPack, mode: selectedMode, seed: seed.map { UInt64(bitPattern: Int64($0)) } ?? UInt64.random(in: .min ... .max))
        mapNavigationActive = true
        focusedControl = .map
        if selectedMode == .explore {
            narration.presentPrompt("Move around the map to discover countries. Press Select to learn about the highlighted country. Move up at the northern edge to reach the zoom controls.")
        }
    }

    private func phaseChanged(_ phase: WorldQuestEngine.Phase?) {
        guard let engine else { return }
        if phase == .answering { presentQuestion() }
        else if phase == .feedback {
            promptTask?.cancel()
            waitingForVoiceOverStart = false
            focusedCountryID = engine.target?.id
            mapNavigationActive = false
            focusedControl = .next
            narration.presentPrompt(statusText(engine) + " Press Select to continue.")
        } else if phase == .completed, let session = engine.completion {
            progress.record(session)
            mapNavigationActive = false
            focusedControl = .replay
            narration.presentPrompt("Your world is growing! You found \(session.independentCount) countries independently and \(session.assistedCount) with help. You discovered \(session.revealedCount) more places.")
        }
    }

    private func presentQuestion() {
        guard let engine, engine.phase == .answering else { return }
        // Each question begins at the same neutral location, independent of its answer.
        focusedCountryID = navigation?.initialID
        mapNavigationActive = true
        focusedControl = .map
        let instructions = engine.questionIndex == 0 ? " Move to a country, then press Select. Move up at the northern edge for zoom or help." : ""
        speakPausingClock(engine.prompt + instructions)
    }

    private func speakPausingClock(_ text: String) {
        promptTask?.cancel()
        guard let engine else { return }
        engine.suspend(.narration)
        narration.presentPrompt(text)
        if UIAccessibility.isVoiceOverRunning {
            // VoiceOver owns speech; explicit readiness avoids timing its announcement.
            waitingForVoiceOverStart = engine.phase == .answering
            if waitingForVoiceOverStart {
                mapNavigationActive = false
                focusedControl = .resume
            }
            return
        }
        promptTask = Task { @MainActor in
            do {
                // Give AVSpeechSynthesizer time to begin before observing completion.
                try await Task.sleep(for: .milliseconds(300))
                while narration.isNarrating {
                    try await Task.sleep(for: .milliseconds(100))
                }
                guard !Task.isCancelled else { return }
                engine.resume(.narration)
            } catch { }
        }
    }

    private func suspendForInterruption() {
        mapNavigationActive = false
        engine?.suspend(.interruption)
        narration.stop()
        promptTask?.cancel()
        if engine?.phase == .answering {
            focusedControl = .resume
        }
    }

    private func repeatGuidance() {
        guard let engine else { return }
        if engine.phase == .answering {
            speakPausingClock(engine.prompt)
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: engine.prompt)
            }
        } else if engine.phase == .feedback { narration.presentPrompt(statusText(engine)) }
        else if engine.phase == .exploring {
            narration.presentPrompt(exploreDetail ?? focusedCountry.map { "\($0.name). \($0.continent.rawValue)." } ?? "Move around the map to discover countries.")
        } else { narration.repeatPrompt() }
    }

    private func selectMap(_ engine: WorldQuestEngine) {
        if engine.phase == .feedback { engine.advance(); return }
        guard let country = focusedCountry else { return }
        if engine.phase == .exploring {
            exploreDetail = "\(country.name) is in \(country.continent.rawValue)."
            if let exploreDetail { narration.presentPrompt(exploreDetail) }
        } else if engine.phase == .answering, !engine.isSuspended {
            let correct = engine.submit(countryID: country.id)
            if !correct, engine.phase == .answering { narration.announce("Try another place. You can do it.") }
        }
    }

    private func move(_ direction: MoveCommandDirection, engine: WorldQuestEngine) {
        guard mapNavigationActive, let id = focusedCountryID else { return }
        guard let navigation else { return }
        let move: WorldQuestNavigation.Direction
        switch direction {
        case .up: move = .up
        case .down: move = .down
        case .left: move = .left
        case .right: move = .right
        @unknown default: return
        }
        if let next = navigation.neighbor(from: id, direction: move) {
            focusedCountryID = next
        } else if direction == .up {
            mapNavigationActive = false
            Task { @MainActor in
                await Task.yield()
                focusedControl = .world
            }
        }
    }

    private func controlGuidance(_ control: Control) -> String {
        switch control {
        case .map: return "Move to a country, then press Select."
        case .world: return "World view. Press Select to see the whole world."
        case .region: return "Region view. Press Select to zoom into your highlighted region."
        case .close: return "Closer view. Press Select to look closely at your highlighted location."
        case .hint: return "Hint. Press Select for a continent clue."
        case .reveal: return "Reveal. Press Select to discover the answer."
        case .resume: return "Ready? Press Select to begin finding the country."
        case .next: return "Press Select to continue your adventure."
        case .start: return "Start exploring. Press Select to begin \(selectedMode.rawValue) in \(selectedPack.rawValue)."
        case .replay: return "Another adventure. Press Select to choose countries and play again."
        case .info: return "Map information for parents."
        case .pack(let pack): return "\(pack.rawValue). \(engine?.catalog.countries(in: pack).count ?? 0) countries. Press Select to choose."
        case .mode(let mode): return "\(mode.rawValue). \(mode.detail). Press Select to choose."
        }
    }

    private func control(for zoom: WorldQuestZoom) -> Control {
        switch zoom { case .world: .world; case .region: .region; case .close: .close }
    }

    private func questionTitle(_ engine: WorldQuestEngine) -> String {
        if engine.phase == .exploring { return focusedCountry?.name ?? "Explore the world" }
        if engine.phase == .feedback { return engine.target?.name ?? "A new place!" }
        return engine.prompt
    }

    private func statusText(_ engine: WorldQuestEngine) -> String {
        if engine.phase == .exploring { return exploreDetail ?? focusedCountry?.continent.rawValue ?? "Move to discover a country" }
        if engine.phase == .feedback, let answer = engine.answers.last, let target = engine.target {
            switch answer.outcome {
            case .independent: return "You found \(target.name)! A stamp for your passport."
            case .assisted: return "You found \(target.name) with a little help!"
            case .revealed: return "Here is \(target.name), in \(target.continent.rawValue)."
            }
        }
        if engine.needsResume { return "Adventure paused. Choose Resume when you are ready." }
        if waitingForVoiceOverStart { return "Choose Start country when you are ready." }
        if engine.isSuspended { return "Listen to the country name, then find its location." }
        if let continent = engine.hintContinent { return "Look in \(continent.rawValue)." }
        if engine.lastWrongID != nil { return "Try another place. You can do it." }
        return engine.mode == .timed ? "Ready for a little expedition?" : "Take your time. The world is yours to explore."
    }

    private func mapAccessibilityLabel(_ engine: WorldQuestEngine) -> String {
        if engine.phase == .exploring { return focusedCountry.map { "\($0.name). \($0.continent.rawValue)." } ?? "World map" }
        if engine.phase == .feedback { return statusText(engine) }
        return "\(engine.prompt) \(focusedCountry?.locationDescription ?? "World map")"
    }
}
