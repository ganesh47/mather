import SwiftUI

/// A spoken, untimed journey from movable objects to comparisons and new contexts.
@MainActor
struct CompareCampTVView: View {
    @State private var game = CompareCampEngine()
    @State private var passport = CompareCampPassportStore()
    @State private var narration = TVNarrationController()
    @State private var selectedRegion = CompareCampRegion.woodland
    @State private var pendingCategory: CompareCampCategory?
    @State private var selectedActivity = CompareCampActivity.adventure
    @State private var selectedDifficulty = CompareCampDifficulty.small
    @State private var showingPassport = false
    @State private var focusTask: Task<Void, Never>?
    @FocusState private var focusedControl: String?

    private let contentWidth: CGFloat = 1680

    var body: some View {
        ZStack {
            MatherTVBackdrop()
            if showingPassport {
                passportScreen
            } else {
                switch game.phase {
                case .choosingCamp:
                    if let pendingCategory { trailChooser(category: pendingCategory) }
                    else { campChooser }
                case .playing:
                    if let round = game.round {
                        playScreen(round: round)
                            .id("round-\(game.seed)-\(round.index)")
                            .task {
                                await Task.yield()
                                guard !Task.isCancelled else { return }
                                focus(preferredRoundFocus)
                            }
                    }
                case .completed:
                    completionScreen
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { presentScreen() }
        .onChange(of: focusedControl) { _, _ in narration.focus(focusedNarration) }
        .onChange(of: game.completion?.id) { _, _ in
            if let result = game.completion { passport.record(result) }
        }
        .onPlayPauseCommand { narration.presentPrompt(repeatablePrompt) }
        .onDisappear {
            focusTask?.cancel()
            narration.stop()
        }
    }

    private var campChooser: some View {
        VStack(alignment: .leading, spacing: 25) {
            chooserHeader(subtitle: "Pick a place. Build, count, and discover together.")
            campHero
            regionShelf
            HStack(spacing: 24) {
                ForEach(selectedRegion.categories) { category in
                    Button {
                        pendingCategory = category
                        presentScreen()
                    } label: {
                        CompareCampCategoryCard(category: category,
                                                focused: focusedControl == categoryFocus(category),
                                                explored: passport.progress.completedCampIDs.contains(category.id))
                    }
                    .buttonStyle(CompareCampButtonStyle())
                    .focusEffectDisabled()
                    .focused($focusedControl, equals: categoryFocus(category))
                    .accessibilityLabel("\(category.title). \(category.subtitle).")
                    .accessibilityHint("Choose this camp, then pick a trail.")
                    .accessibilityIdentifier(categoryFocus(category))
                }
            }
            .focusSection()
            HStack(spacing: 14) {
                Label("24 camps", systemImage: "map.fill")
                Text("·")
                Text("6 ways to play")
                Text("·")
                Text("No timer. Every little step counts.")
                Spacer()
                Label("Play/Pause  ·  Listen again", systemImage: "speaker.wave.2.fill")
            }
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.62))
            .padding(.top, 3)
        }
        .frame(width: contentWidth, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 90)
        .padding(.vertical, 76)
    }

    private func chooserHeader(subtitle: String) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Compare Camp")
                    .font(.system(size: 62, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("tv-compare-title")
                Text(subtitle)
                    .font(.system(size: 27, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.71))
            }
            Spacer()
            smallButton("Camp passport", symbol: "book.closed.fill", id: "tv-compare-passport", width: 280) {
                showingPassport = true
                presentScreen()
            }
        }
    }

    private var campHero: some View {
        ZStack(alignment: .leading) {
            Image("CompareCampLandscape")
                .resizable()
                .scaledToFill()
                .frame(width: contentWidth, height: 213)
                .clipped()
                .accessibilityHidden(true)
            LinearGradient(colors: [CompareCampPalette.ink.opacity(0.95), CompareCampPalette.ink.opacity(0.73), .clear], startPoint: .leading, endPoint: .trailing)
            HStack(spacing: 28) {
                CompareCampArtwork(assetName: "CompareCampGuide", symbolName: "pawprint.fill", accent: CompareCampPalette.gold)
                    .frame(width: 160, height: 166)
                VStack(alignment: .leading, spacing: 12) {
                    Text("A big world of little discoveries")
                        .font(.system(size: 37, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Meet forest friends, reef fish, planets, and busy builders.\nFind what matches. Help a camp grow. Count the extras.")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.83))
                }
                Spacer()
            }
            .padding(.horizontal, 34)
        }
        .frame(width: contentWidth, height: 213)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.14), lineWidth: 2))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your camp guide is ready. Explore 24 camps across six places, with six ways to play.")
    }

    private var regionShelf: some View {
        HStack(spacing: 16) {
            ForEach(CompareCampRegion.allCases) { region in
                let id = "tv-compare-region-\(region.id)"
                Button {
                    selectedRegion = region
                    narration.presentPrompt("\(region.title). Four camps to explore. Choose a picture to pick your camp.")
                    focus(categoryFocus(region.categories[0]))
                } label: {
                    Label(region.title, systemImage: region.symbolName)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(width: 266.6, height: 80)
                        .modifier(CompareCampControlSurface(focused: focusedControl == id, selected: selectedRegion == region, radius: 20))
                }
                .buttonStyle(CompareCampButtonStyle())
                .focusEffectDisabled()
                .focused($focusedControl, equals: id)
                .onMoveCommand { bridgeFocus($0, from: id) }
                .accessibilityLabel("\(region.title). Four camps. \(selectedRegion == region ? "Selected." : "")")
                .accessibilityIdentifier(id)
            }
        }
        .focusSection()
    }

    private func trailChooser(category: CompareCampCategory) -> some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack(spacing: 28) {
                CompareCampArtwork(assetName: category.artAssetName, symbolName: category.tokenSymbol, accent: CompareCampPalette.color(category.accentHex))
                    .frame(width: 116, height: 108)
                VStack(alignment: .leading, spacing: 8) {
                    Text(category.title)
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("tv-compare-title")
                    Text("Choose your trail. Eight discoveries, at your own pace.")
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.70))
                }
                Spacer()
                smallButton("Other camps", symbol: "map.fill", id: "tv-compare-camps", width: 255) { chooseCamps() }
            }
            Text("How shall we play?")
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .foregroundStyle(CompareCampPalette.mint)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(544), spacing: 24), count: 3), spacing: 19) {
                ForEach(CompareCampActivity.allCases) { activity in
                    activityButton(activity)
                }
            }
            .focusSection()
            Text("Pick a group size")
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .foregroundStyle(CompareCampPalette.sky)
                .padding(.top, 3)
            HStack(spacing: 24) {
                ForEach(CompareCampDifficulty.allCases) { difficulty in
                    difficultyButton(difficulty)
                }
            }
            .focusSection()
            HStack(spacing: 28) {
                smallButton("Start exploring", symbol: "play.fill", id: "tv-compare-start", width: 388, accent: CompareCampPalette.mint) { start(category: category) }
                Label("Count together, pair up, and try again whenever you like.", systemImage: "heart.fill")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
            }
            .padding(.top, 6)
        }
        .frame(width: contentWidth, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 90)
        .padding(.vertical, 76)
    }

    private func activityButton(_ activity: CompareCampActivity) -> some View {
        let id = "tv-compare-activity-\(activity.id)"
        let isFocused = focusedControl == id
        return Button {
            selectedActivity = activity
            narration.presentPrompt("\(activity.title). \(activity.subtitle). Selected. \(selectedDifficulty.title), \(selectedDifficulty.subtitle). Choose a group size or Start Exploring.")
        } label: {
            HStack(spacing: 21) {
                Image(systemName: activity.symbolName)
                    .font(.system(size: 34, weight: .bold))
                    .frame(width: 49)
                    .foregroundStyle(isFocused ? CompareCampPalette.ink : CompareCampPalette.mint)
                VStack(alignment: .leading, spacing: 7) {
                    Text(activity.title)
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(activity.subtitle)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(isFocused ? CompareCampPalette.ink.opacity(0.7) : .white.opacity(0.64))
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                if selectedActivity == activity {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                }
            }
            .padding(25)
            .frame(width: 544, height: 138)
            .modifier(CompareCampControlSurface(focused: isFocused, selected: selectedActivity == activity))
        }
        .buttonStyle(CompareCampButtonStyle())
        .focusEffectDisabled()
        .focused($focusedControl, equals: id)
        .onMoveCommand { bridgeFocus($0, from: id) }
        .accessibilityLabel("\(activity.title). \(activity.subtitle). \(selectedActivity == activity ? "Selected." : "")")
        .accessibilityIdentifier(id)
    }

    private func difficultyButton(_ difficulty: CompareCampDifficulty) -> some View {
        let id = "tv-compare-difficulty-\(difficulty.id)"
        let isFocused = focusedControl == id
        return Button {
            selectedDifficulty = difficulty
            narration.presentPrompt("\(difficulty.title). \(difficulty.subtitle). Selected. \(selectedActivity.title). Choose Start Exploring when you are ready.")
        } label: {
            HStack(spacing: 20) {
                Image(systemName: difficulty == .small ? "leaf.fill" : difficulty == .growing ? "tree.fill" : "mountain.2.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(isFocused ? CompareCampPalette.ink : CompareCampPalette.sky)
                    .frame(width: 45)
                VStack(alignment: .leading, spacing: 7) {
                    Text(difficulty.title)
                        .font(.system(size: 27, weight: .black, design: .rounded))
                    Text(difficulty.subtitle)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(isFocused ? CompareCampPalette.ink.opacity(0.7) : .white.opacity(0.64))
                }
                Spacer(minLength: 0)
                if selectedDifficulty == difficulty { Image(systemName: "checkmark.circle.fill") }
            }
            .padding(25)
            .frame(width: 544, height: 112)
            .modifier(CompareCampControlSurface(focused: isFocused, selected: selectedDifficulty == difficulty, accent: CompareCampPalette.sky))
        }
        .buttonStyle(CompareCampButtonStyle())
        .focusEffectDisabled()
        .focused($focusedControl, equals: id)
        .onMoveCommand { bridgeFocus($0, from: id) }
        .accessibilityLabel("\(difficulty.title). \(difficulty.subtitle). \(selectedDifficulty == difficulty ? "Selected." : "")")
        .accessibilityIdentifier(id)
    }

    private func playScreen(round: CompareCampRound) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            playHeader(round)
            HStack(alignment: .top, spacing: 30) {
                comparisonBoard(round)
                answerPanel(round)
            }
            roundFeedback(round)
            HStack {
                Label("Play/Pause  ·  Hear the question", systemImage: "speaker.wave.2.fill")
                Spacer()
                Text("Take your time. Your guide is always here.")
            }
            .font(.system(size: 21, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.52))
        }
        .frame(width: contentWidth, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 90)
        .padding(.vertical, 76)
    }

    private func playHeader(_ round: CompareCampRound) -> some View {
        HStack(spacing: 23) {
            CompareCampArtwork(assetName: round.category.artAssetName, symbolName: round.category.tokenSymbol, accent: CompareCampPalette.color(round.category.accentHex))
                .frame(width: 80, height: 80)
            VStack(alignment: .leading, spacing: 7) {
                Text(round.category.title)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("tv-compare-title")
                Text("\(game.progressText)  ·  \(round.stage.title)")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .accessibilityIdentifier("tv-compare-progress")
            }
            Spacer()
            CompareCampTrailProgress(completed: game.completedRoundCount, goal: game.roundGoal)
            smallButton("Camps", symbol: "map.fill", id: "tv-compare-camps", width: 164) { chooseCamps() }
        }
        .frame(height: 88)
    }

    private func comparisonBoard(_ round: CompareCampRound) -> some View {
        let revealNumbers = round.stage == .abstract || game.hasSolvedRound || game.hintShown
        return VStack(alignment: .leading, spacing: 19) {
            HStack {
                Text(round.activity == .makeEqual ? "Help the left camp match the right" : round.stage == .transfer ? "New friends. Same clever thinking." : "Look at each group")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(CompareCampPalette.sky)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                if round.stage == .abstract || game.hasSolvedRound {
                    Text(game.hasSolvedRound ? "\(game.currentLeftCount) \(currentRelation.symbol) \(game.currentRightCount)" : "\(game.currentLeftCount) ? \(game.currentRightCount)")
                        .font(.system(size: 37, weight: .black, design: .rounded))
                        .foregroundStyle(CompareCampPalette.mint)
                        .accessibilityIdentifier("tv-compare-number-comparison")
                }
            }
            .frame(height: 45)
            HStack(spacing: 24) {
                CompareCampTokenTray(category: round.category, title: "Left camp", count: game.currentLeftCount, maxCount: round.maxCount,
                                     counted: game.countedLeft, arranged: game.isArranged, pairedCount: game.pairedCount,
                                     showCount: revealNumbers || game.countedLeft >= game.currentLeftCount,
                                     isBuilding: round.activity == .makeEqual, accent: CompareCampPalette.gold)
                    .accessibilityIdentifier("tv-compare-left-group")
                CompareCampTokenTray(category: round.category, title: "Right camp", count: game.currentRightCount, maxCount: round.maxCount,
                                     counted: game.countedRight, arranged: game.isArranged, pairedCount: game.pairedCount,
                                     showCount: revealNumbers || game.countedRight >= game.currentRightCount,
                                     isBuilding: false, accent: CompareCampPalette.sky)
                    .accessibilityIdentifier("tv-compare-right-group")
            }
            HStack(spacing: 13) {
                smallButton("Count left", symbol: "hand.tap.fill", id: "tv-compare-count-left", width: 226, height: 79) { count(.left) }
                    .disabled(game.hasSolvedRound)
                smallButton("Count right", symbol: "hand.tap.fill", id: "tv-compare-count-right", width: 226, height: 79) { count(.right) }
                    .disabled(game.hasSolvedRound)
                smallButton("Pair up", symbol: "link", id: "tv-compare-arrange", width: 226, height: 79, accent: CompareCampPalette.sky) {
                    game.arrange()
                    narration.presentPrompt("\(game.currentPrompt) \(pairingPrompt)")
                }
                .disabled(game.hasSolvedRound)
                smallButton("Guide me", symbol: "lightbulb.fill", id: "tv-compare-hint", width: 239, height: 79, accent: CompareCampPalette.gold) {
                    game.showHint()
                    narration.presentPrompt("\(hintPrompt(round)) \(game.currentPrompt)")
                }
                .disabled(game.hasSolvedRound)
            }
            .focusSection()
        }
        .frame(width: 980, alignment: .leading)
    }

    private func answerPanel(_ round: CompareCampRound) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 17) {
                CompareCampArtwork(assetName: "CompareCampGuide", symbolName: "pawprint.fill", accent: CompareCampPalette.gold)
                    .frame(width: 84, height: 96)
                Text(round.question)
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("tv-compare-question")
            }
            .frame(height: 105, alignment: .leading)
            Group {
                if round.activity == .makeEqual {
                    buildControls
                } else {
                    ForEach(round.choices) { choice in answerButton(choice, round: round) }
                }
            }
            .focusSection()
            VStack(alignment: .leading, spacing: 9) {
                Label(round.activity == .makeEqual ? "One change at a time" : game.isArranged ? "Look for the extras" : "You can always ask for help", systemImage: "heart.fill")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(CompareCampPalette.mint)
                Text(round.activity == .makeEqual ? "The right camp stays put.\nAdd or take away on the left, then check." : game.isArranged ? pairingPrompt : "Count together or pair up the pictures.\nA new try is another chance to learn.")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(25)
            .frame(width: 670, alignment: .leading)
            .frame(minHeight: 128, alignment: .leading)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 23))
        }
        .frame(width: 670, alignment: .leading)
    }

    private var buildControls: some View {
        VStack(spacing: 15) {
            HStack(spacing: 20) {
                smallButton("Add one", symbol: "plus.circle.fill", id: "tv-compare-add", width: 325, height: 110) {
                    game.adjustLeft(by: 1)
                    narration.announce("Added one. The left camp now has \(game.currentLeftCount).")
                }
                .disabled(!game.canAdd || game.hasSolvedRound)
                smallButton("Take one", symbol: "minus.circle.fill", id: "tv-compare-remove", width: 325, height: 110, accent: CompareCampPalette.sky) {
                    game.adjustLeft(by: -1)
                    narration.announce("Took one away. The left camp now has \(game.currentLeftCount).")
                }
                .disabled(!game.canRemove || game.hasSolvedRound)
            }
            smallButton("Check match", symbol: "checkmark.circle.fill", id: "tv-compare-check", width: 670, height: 100, accent: CompareCampPalette.mint) {
                _ = game.checkBuild()
                announceAnswer()
            }
            .disabled(game.hasSolvedRound)
        }
    }

    private func answerButton(_ choice: CompareCampChoice, round: CompareCampRound) -> some View {
        let id = "tv-compare-answer-\(choice.id)"
        let isFocused = focusedControl == id
        let isSolved = game.hasSolvedRound && game.selectedAnswerID == choice.id
        return Button {
            _ = game.select(answerID: choice.id)
            announceAnswer()
        } label: {
            HStack(spacing: 22) {
                if round.activity == .symbols || round.activity == .difference {
                    Text(choice.title)
                        .font(.system(size: 51, weight: .black, design: .rounded))
                        .frame(width: 70)
                    Text(choice.spokenTitle)
                        .font(.system(size: 29, weight: .black, design: .rounded))
                } else {
                    Image(systemName: choice.symbolName)
                        .font(.system(size: 35, weight: .black))
                        .frame(width: 47)
                    Text(choice.title)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                }
                Spacer()
                if isSolved { Image(systemName: "checkmark.circle.fill").font(.system(size: 29, weight: .bold)) }
            }
            .padding(.horizontal, 27)
            .frame(width: 670, height: 97)
            .modifier(CompareCampControlSurface(focused: isFocused, selected: isSolved, accent: isSolved ? CompareCampPalette.mint : CompareCampPalette.sky))
        }
        .buttonStyle(CompareCampButtonStyle())
        .focusEffectDisabled()
        .focused($focusedControl, equals: id)
        .onMoveCommand { bridgeFocus($0, from: id) }
        .disabled(game.hasSolvedRound)
        .accessibilityLabel(choice.spokenTitle)
        .accessibilityHint("Choose this answer. You can try again if you need to.")
        .accessibilityIdentifier(id)
    }

    private func roundFeedback(_ round: CompareCampRound) -> some View {
        HStack(spacing: 20) {
            Image(systemName: game.hasSolvedRound ? "checkmark.seal.fill" : game.lastAnswerWasCorrect == false ? "heart.circle.fill" : "pawprint.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(game.hasSolvedRound ? CompareCampPalette.mint : CompareCampPalette.gold)
            VStack(alignment: .leading, spacing: 7) {
                Text(game.hasSolvedRound ? "A little discovery!" : game.lastAnswerWasCorrect == false ? "Let’s explore it together" : round.stage == .transfer ? "Take your thinking somewhere new" : "Small steps. Big discoveries.")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(game.hasSolvedRound ? solvedExplanation(round) : game.feedbackText.isEmpty ? "No timer. Count, pair, or ask your guide." : game.feedbackText)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.71))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .accessibilityIdentifier("tv-compare-feedback")
            }
            Spacer(minLength: 18)
            if game.hasSolvedRound {
                smallButton(game.completedRoundCount == game.roundGoal ? "Finish trail" : "Next stop", symbol: "arrow.right", id: "tv-compare-next", width: 256, height: 78, accent: CompareCampPalette.mint) {
                    focusedControl = nil
                    game.advance()
                    presentScreen()
                }
                .task {
                    await Task.yield()
                    guard !Task.isCancelled else { return }
                    focus("tv-compare-next")
                }
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 17)
        .frame(width: contentWidth, height: 116, alignment: .leading)
        .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 25))
    }

    private var completionScreen: some View {
        VStack(spacing: 25) {
            Text("Compare Camp")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.64))
                .accessibilityIdentifier("tv-compare-title")
            CompareCampArtwork(assetName: "CompareCampBadge", symbolName: "checkmark.seal.fill", accent: CompareCampPalette.gold)
                .frame(width: 230, height: 220)
            Text("Trail explored!")
                .font(.system(size: 66, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("You built, compared, and tried somewhere new.")
                .font(.system(size: 29, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.76))
            CompareCampTrailProgress(completed: game.roundGoal, goal: game.roundGoal)
                .padding(.vertical, 4)
            HStack(spacing: 23) {
                if let category = game.category {
                    CompareCampArtwork(assetName: category.artAssetName, symbolName: category.tokenSymbol, accent: CompareCampPalette.color(category.accentHex))
                        .frame(width: 80, height: 74)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(category.title) sticker collected")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Saved in your camp passport. \(passport.progress.completedCampIDs.count) of 24 camps explored.")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
            }
            .padding(.horizontal, 35)
            .padding(.vertical, 16)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 26))
            HStack(spacing: 25) {
                smallButton("Explore again", symbol: "arrow.clockwise", id: "tv-compare-replay", width: 330, height: 95) {
                    game.replay()
                    presentScreen()
                }
                smallButton("Choose a camp", symbol: "map.fill", id: "tv-compare-camps", width: 330, height: 95, accent: CompareCampPalette.sky) { chooseCamps() }
                smallButton("My passport", symbol: "book.closed.fill", id: "tv-compare-passport", width: 330, height: 95, accent: CompareCampPalette.gold) {
                    showingPassport = true
                    presentScreen()
                }
            }
            .padding(.top, 12)
            .focusSection()
            Text("No rush. Another adventure will be here whenever you are.")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.54))
        }
        .frame(width: contentWidth)
        .padding(.top, 44)
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 90)
        .padding(.vertical, 76)
    }

    private var passportScreen: some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("My camp passport")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("tv-compare-passport-title")
                    Text("\(passport.progress.completedCampIDs.count) of 24 camps explored  ·  \(passport.progress.totalSessionCount) \(passport.progress.totalSessionCount == 1 ? "trail" : "trails") completed")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .accessibilityIdentifier("tv-compare-passport-progress")
                }
                Spacer()
                smallButton("Back to camp", symbol: "chevron.backward", id: "tv-compare-passport-back", width: 284) {
                    showingPassport = false
                    presentScreen()
                }
            }
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 25) {
                    ForEach(CompareCampRegion.allCases) { region in
                        VStack(alignment: .leading, spacing: 14) {
                            Label(region.title, systemImage: region.symbolName)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(CompareCampPalette.sky)
                            HStack(spacing: 24) {
                                ForEach(region.categories) { category in passportSticker(category) }
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
            }
            .frame(height: 660)
            Text("Choose a sticker to explore that camp. Your passport stays on this Apple TV.")
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(width: contentWidth, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 90)
        .padding(.vertical, 76)
    }

    private func passportSticker(_ category: CompareCampCategory) -> some View {
        let explored = passport.progress.completedCampIDs.contains(category.id)
        let id = "tv-compare-sticker-\(category.id)"
        let isFocused = focusedControl == id
        return Button {
            selectedRegion = category.region
            pendingCategory = category
            showingPassport = false
            game.chooseAnotherCamp()
            presentScreen()
        } label: {
            HStack(spacing: 18) {
                CompareCampArtwork(assetName: category.artAssetName, symbolName: category.tokenSymbol, accent: CompareCampPalette.color(category.accentHex))
                    .frame(width: 86, height: 85)
                    .opacity(explored ? 1 : 0.42)
                VStack(alignment: .leading, spacing: 6) {
                    Text(category.title)
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .lineLimit(2)
                    Label(explored ? "Explored" : "Ready to discover", systemImage: explored ? "checkmark.seal.fill" : "sparkle")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(isFocused ? CompareCampPalette.ink.opacity(0.7) : .white.opacity(0.64))
                }
                Spacer(minLength: 0)
            }
            .padding(21)
            .frame(width: 400, height: 146)
            .modifier(CompareCampControlSurface(focused: isFocused, selected: explored, accent: CompareCampPalette.color(category.accentHex)))
        }
        .buttonStyle(CompareCampButtonStyle())
        .focusEffectDisabled()
        .focused($focusedControl, equals: id)
        .accessibilityLabel("\(category.title). \(explored ? "Explored. Sticker collected." : "Ready to discover.")")
        .accessibilityHint("Choose this camp for another adventure.")
        .accessibilityIdentifier(id)
    }

    private func smallButton(_ title: String, symbol: String, id: String, width: CGFloat, height: CGFloat = 80,
                             accent: Color = CompareCampPalette.mint, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: symbol).font(.system(size: 26, weight: .bold))
                Text(title)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)
            }
            .frame(width: width, height: height)
            .modifier(CompareCampControlSurface(focused: focusedControl == id, accent: accent, radius: 20))
        }
        .buttonStyle(CompareCampButtonStyle())
        .focusEffectDisabled()
        .focused($focusedControl, equals: id)
        .onMoveCommand { bridgeFocus($0, from: id) }
        .accessibilityLabel(title)
        .accessibilityIdentifier(id)
    }

    private var currentRelation: CompareCampRelation {
        .comparing(game.currentLeftCount, game.currentRightCount)
    }

    private var pairingPrompt: String {
        if game.currentLeftCount == game.currentRightCount { return "Every picture has a partner. There are no extras." }
        let extraSide = game.currentLeftCount > game.currentRightCount ? "left" : "right"
        return "Pictures with a link have a partner. Pictures with a plus are the extras on the \(extraSide). Count them together."
    }

    private var numberSignTeaching: String {
        "The open side of the sign faces the bigger number. The pointed tip faces the smaller number. For a match, choose the equal sign, with two flat lines."
    }

    private func hintPrompt(_ round: CompareCampRound) -> String {
        if round.activity == .symbols { return "\(pairingPrompt) \(numberSignTeaching)" }
        if round.activity == .makeEqual {
            let direction = game.currentLeftCount < game.currentRightCount ? "add" : game.currentLeftCount > game.currentRightCount ? "take away" : "check"
            return "Line up one partner from each camp. Look for the extras. Try \(direction) on the left, then check the match."
        }
        return "\(pairingPrompt) \(round.activity == .fewer ? "Choose the group with fewer, or a smaller number." : round.activity == .difference ? "Choose how many do not have a partner." : "Now compare the two groups.")"
    }

    private func solvedExplanation(_ round: CompareCampRound) -> String {
        if round.activity == .makeEqual { return "Both camps have \(game.currentLeftCount) \(round.category.tokenPlural). Every picture has a partner." }
        return round.explanation
    }

    private func categoryFocus(_ category: CompareCampCategory) -> String { "tv-compare-category-\(category.id)" }

    private func start(category: CompareCampCategory) {
        narration.stop()
        game.start(category: category, activity: selectedActivity, difficulty: selectedDifficulty,
                   seed: UInt64(passport.progress.resultCount(for: category.id)))
        pendingCategory = nil
        presentScreen()
    }

    private func chooseCamps() {
        narration.stop()
        pendingCategory = nil
        showingPassport = false
        game.chooseAnotherCamp()
        presentScreen()
    }

    private func count(_ side: CompareCampSide) {
        let value = game.countNext(side: side)
        let count = side == .left ? game.currentLeftCount : game.currentRightCount
        narration.announce(value.map { "\($0)" } ?? "The \(side.rawValue) camp has \(count). All counted.")
    }

    private func announceAnswer() {
        if game.hasSolvedRound {
            narration.presentPrompt(repeatablePrompt)
            focus("tv-compare-next")
        } else {
            narration.presentPrompt("\(game.feedbackText) \(game.currentPrompt)")
        }
    }

    private func focus(_ id: String) {
        focusTask?.cancel()
        focusTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            focusedControl = id
        }
    }

    private var preferredRoundFocus: String {
        if game.hasSolvedRound { return "tv-compare-next" }
        if game.round?.activity == .makeEqual { return game.canAdd ? "tv-compare-add" : "tv-compare-remove" }
        return "tv-compare-answer-\(game.round?.choices.first?.id ?? "left")"
    }

    private func presentScreen() {
        if showingPassport {
            narration.presentPrompt("Your camp passport. \(passport.progress.completedCampIDs.count) of 24 camps explored. Swipe down to explore your stickers, or choose Back to Camp.")
            focus("tv-compare-passport-back")
        } else {
            switch game.phase {
            case .choosingCamp:
                if let category = pendingCategory {
                    narration.presentPrompt("\(category.title). Choose how to play, then choose a group size. Camp Adventure takes you through building, pictures, number signs, and a new place. Press select on Start Exploring when you are ready.")
                    focus("tv-compare-activity-\(selectedActivity.id)")
                } else {
                    narration.presentPrompt("Welcome to Compare Camp. Pick a camp picture to explore. Swipe up to choose another place. There are 24 camps, with no timer. Press Play Pause to listen again.")
                    focus(categoryFocus(selectedRegion.categories[0]))
                }
            case .playing:
                narration.presentPrompt(repeatablePrompt)
                focusedControl = nil
                // The newly mounted round restores focus in its own view task.
            case .completed:
                narration.presentPrompt("Trail explored! You finished all eight stops. Your camp sticker is saved in your passport. Explore again for new groups, choose another camp, or visit your passport.")
                focus("tv-compare-replay")
            }
        }
    }

    private var repeatablePrompt: String {
        if showingPassport {
            return "Your camp passport. \(passport.progress.completedCampIDs.count) of 24 camps explored. Choose a sticker to explore that camp, or Back to Camp."
        }
        if let category = pendingCategory {
            return "\(category.title). \(selectedActivity.title). \(selectedDifficulty.title), \(selectedDifficulty.subtitle). Choose Start Exploring when you are ready."
        }
        if game.phase == .playing, let round = game.round {
            if game.hasSolvedRound {
                return "\(solvedExplanation(round)) Press select on \(game.completedRoundCount == game.roundGoal ? "Finish Trail" : "Next Stop") to continue."
            }
            let feedback = game.lastAnswerWasCorrect == false ? "\(game.feedbackText) " : ""
            let signIntroduction = round.activity == .symbols && round.index == 4 ? " \(numberSignTeaching)" : ""
            return "\(feedback)\(game.currentPrompt)\(signIntroduction)\(game.isArranged ? " \(pairingPrompt)" : "")"
        }
        return narration.currentPrompt ?? game.currentPrompt
    }

    /// Bridges the intentional gaps between the object board and answer controls.
    /// Movement within each row or column continues to use the native focus engine.
    private func bridgeFocus(_ direction: MoveCommandDirection, from id: String) {
        guard focusedControl == id, !showingPassport else { return }
        if game.phase == .choosingCamp {
            if pendingCategory != nil {
                if id.hasPrefix("tv-compare-difficulty-"), direction == .down { focus("tv-compare-start") }
                else if id == "tv-compare-start", direction == .up { focus("tv-compare-difficulty-\(selectedDifficulty.id)") }
                else if id == "tv-compare-camps", direction == .down { focus("tv-compare-activity-\(selectedActivity.id)") }
            } else {
                if id.hasPrefix("tv-compare-region-"), direction == .up { focus("tv-compare-passport") }
                else if id == "tv-compare-passport", direction == .down { focus("tv-compare-region-\(selectedRegion.id)") }
            }
            return
        }
        guard game.phase == .playing, !game.hasSolvedRound else { return }
        let firstAction = game.round?.activity == .makeEqual
            ? (game.canAdd ? "tv-compare-add" : "tv-compare-remove")
            : "tv-compare-answer-\(game.round?.choices.first?.id ?? "left")"
        let supportIDs = ["tv-compare-count-left", "tv-compare-count-right", "tv-compare-arrange", "tv-compare-hint"]
        if id == "tv-compare-check", direction == .down { focus("tv-compare-count-left") }
        else if (id == "tv-compare-check" || id == "tv-compare-add" || id.hasPrefix("tv-compare-answer-")), direction == .left { focus("tv-compare-hint") }
        else if id == "tv-compare-hint", direction == .right { focus(game.round?.activity == .makeEqual ? "tv-compare-check" : firstAction) }
        else if supportIDs.contains(id), direction == .up { focus(firstAction) }
        else if id == "tv-compare-camps", direction == .down { focus(firstAction) }
        else if id == "tv-compare-answer-\(game.round?.choices.last?.id ?? "")", direction == .down { focus("tv-compare-count-left") }
    }

    private var focusedNarration: String? {
        guard let id = focusedControl else { return nil }
        if let category = CompareCampCategory.all.first(where: { categoryFocus($0) == id || "tv-compare-sticker-\($0.id)" == id }) {
            return "\(category.title). \(category.subtitle). Press select to explore."
        }
        if let region = CompareCampRegion.allCases.first(where: { "tv-compare-region-\($0.id)" == id }) { return "\(region.title). Four camps to explore." }
        if let activity = CompareCampActivity.allCases.first(where: { "tv-compare-activity-\($0.id)" == id }) { return "\(activity.title). \(activity.subtitle). \(selectedActivity == activity ? "Selected." : "Press select to choose.")" }
        if let difficulty = CompareCampDifficulty.allCases.first(where: { "tv-compare-difficulty-\($0.id)" == id }) { return "\(difficulty.title). \(difficulty.subtitle). \(selectedDifficulty == difficulty ? "Selected." : "Press select to choose.")" }
        if let choice = game.round?.choices.first(where: { "tv-compare-answer-\($0.id)" == id }) { return choice.spokenTitle }
        switch id {
        case "tv-compare-start": return "Start exploring. \(selectedActivity.title). \(selectedDifficulty.title). Eight stops with no timer."
        case "tv-compare-add": return "Add one to the left camp."
        case "tv-compare-remove": return "Take one away from the left camp."
        case "tv-compare-check": return "Check match. See whether every picture has a partner."
        case "tv-compare-count-left": return "Count the left camp, one picture at a time. Press select for each picture."
        case "tv-compare-count-right": return "Count the right camp, one picture at a time. Press select for each picture."
        case "tv-compare-arrange": return "Pair up. Line up a partner from each group to spot the extras."
        case "tv-compare-hint": return "Guide me. Your camp guide will help you think it through."
        case "tv-compare-next": return game.completedRoundCount == game.roundGoal ? "Finish trail. Collect your camp sticker." : "Next stop. Keep exploring."
        case "tv-compare-replay": return "Explore again. New groups in this camp."
        case "tv-compare-camps": return "Choose another camp."
        case "tv-compare-passport": return "Camp passport. See the camps you explored."
        case "tv-compare-passport-back": return "Back to camp."
        default: return nil
        }
    }
}

#Preview { CompareCampTVView() }
