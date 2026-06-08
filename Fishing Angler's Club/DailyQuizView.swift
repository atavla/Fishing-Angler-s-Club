import Combine
import SwiftUI

struct DailyQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = DailyQuizViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground(assetName: "background_quiz")

                if viewModel.isFinished {
                    resultView
                } else {
                    ZStack {
                        questionView
                        if viewModel.answerState != .unanswered {
                            feedbackPopup
                                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        }
                    }
                }
            }
            .foregroundStyle(.white)
            .navigationTitle("Icebreaker Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .interactiveDismissDisabled(!viewModel.isFinished)
            .toolbar {
                if viewModel.isFinished {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
            }
        }
        .onDisappear { viewModel.stopTimer() }
        .onChange(of: viewModel.isFinished) { _, isFinished in
            if isFinished {
                _ = viewModel.commitResultIfNeeded(in: appState)
            }
        }
    }

    private var questionView: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Text("Question \(viewModel.questionIndex + 1) of \(viewModel.questions.count)")
                    Spacer()
                    Text("\(viewModel.score) correct")
                }
                .font(.subheadline.weight(.semibold))

                timerView

                GlassCard {
                    Text(viewModel.currentQuestion.text)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 110)
                }

                VStack(spacing: 12) {
                    ForEach(Array(viewModel.currentQuestion.answers.enumerated()), id: \.offset) { index, answer in
                        Button {
                            viewModel.answer(index)
                        } label: {
                            HStack {
                                Text(["A", "B", "C", "D"][index])
                                    .font(.headline.monospaced())
                                Text(answer)
                                    .font(.headline)
                                Spacer()
                                answerIcon(for: index)
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 58)
                            .background { answerBackground(for: index) }
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.answerState != .unanswered)
                    }
                }
            }
            .padding()
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.answerState)
        }
    }

    private var timerView: some View {
        VStack(spacing: 7) {
            HStack {
                AssetArtwork(name: "icon_quiz_timer", scaling: .contain, cornerRadius: 5)
                    .frame(width: 24, height: 24)
                Text("\(viewModel.secondsRemaining)s")
                    .font(.title3.monospacedDigit().bold())
                Spacer()
            }
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.22))
                    }

                GeometryReader { proxy in
                    Capsule()
                        .fill(timerColor)
                        .frame(width: proxy.size.width * viewModel.timeProgress)
                        .animation(.linear(duration: 0.25), value: viewModel.timeProgress)
                }
            }
            .frame(height: 14)
            .accessibilityLabel("Time remaining")
            .accessibilityValue("\(viewModel.secondsRemaining) seconds")
        }
    }

    private var timerColor: Color {
        switch viewModel.secondsRemaining {
        case 0...5:
            AppTheme.danger
        case 6...12:
            AppTheme.orange
        default:
            AppTheme.emerald
        }
    }

    private var feedbackPopup: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            GlassCard {
                VStack(spacing: 14) {
                    AssetArtwork(
                        name: viewModel.wasCorrect ? "quiz_correct_popup_icon" : "quiz_incorrect_popup_icon",
                        scaling: .contain
                    )
                    .frame(height: 112)

                    Text(viewModel.feedbackTitle)
                        .font(.title2.bold())
                    Text(viewModel.feedbackMessage)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                        .multilineTextAlignment(.center)

                    Button(viewModel.isLastQuestion ? "See results" : "Next question") {
                        viewModel.advance()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(28)
            .frame(maxWidth: 430)
        }
        .accessibilityAddTraits(.isModal)
    }

    private var resultView: some View {
        ScrollView {
            GlassCard {
                VStack(spacing: 22) {
                    AssetArtwork(
                        name: viewModel.score == 5 ? "quiz_victory_popup_icon" : "quiz_incorrect_popup_icon",
                        scaling: .contain
                    )
                    .frame(height: 180)

                    Text(viewModel.score == 5 ? "Perfect catch!" : "The ice held firm")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("You answered \(viewModel.score) of 5 questions correctly.")
                        .font(.title3)
                        .multilineTextAlignment(.center)

                    Text(viewModel.score == 5
                         ? "You earned 100 XP and unlocked a scratch card."
                         : "You earned \(viewModel.score * 10) XP. Come back after midnight for another attempt.")
                        .foregroundStyle(.white.opacity(0.78))
                        .multilineTextAlignment(.center)

                    if viewModel.score == 5 {
                        Button("Open scratch card") {
                            if let reward = viewModel.commitResultIfNeeded(in: appState) {
                                dismiss()
                                Task { @MainActor in
                                    try? await Task.sleep(for: .milliseconds(250))
                                    appState.presentedScratchBonus = reward
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("Back to the pier") {
                            _ = viewModel.commitResultIfNeeded(in: appState)
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private func answerIcon(for index: Int) -> some View {
        switch viewModel.answerState {
        case .correct(let selected) where selected == index:
            Image(systemName: "checkmark.circle.fill")
        case .incorrect(let selected, _) where selected == index:
            Image(systemName: "xmark.circle.fill")
        case .incorrect(_, let correct) where correct == index,
             .timedOut(let correct) where correct == index:
            Image(systemName: "checkmark.circle.fill")
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func answerBackground(for index: Int) -> some View {
        switch viewModel.answerState {
        case .correct(let selected) where selected == index:
            RoundedRectangle(cornerRadius: 16).fill(AppTheme.emerald)
        case .incorrect(let selected, _) where selected == index:
            RoundedRectangle(cornerRadius: 16).fill(AppTheme.danger)
        case .incorrect(_, let correct) where correct == index,
             .timedOut(let correct) where correct == index:
            RoundedRectangle(cornerRadius: 16).fill(AppTheme.emerald.opacity(0.78))
        default:
            GlassPanelBackground(cornerRadius: 16)
        }
    }
}

@MainActor
final class DailyQuizViewModel: ObservableObject {
    @Published private(set) var questions = QuizContent.dailyQuestions()
    @Published private(set) var questionIndex = 0
    @Published private(set) var score = 0
    @Published private(set) var secondsRemaining = 30
    @Published private(set) var answerState: QuizAnswerState = .unanswered
    @Published private(set) var isFinished = false

    private var timerTask: Task<Void, Never>?
    private var committedReward: RewardBonus?
    private var didCommit = false

    init() {
        startTimer()
    }

    var currentQuestion: QuizQuestion { questions[questionIndex] }
    var timeProgress: Double { Double(secondsRemaining) / 30 }
    var isLastQuestion: Bool { questionIndex == questions.count - 1 }

    var wasCorrect: Bool {
        if case .correct = answerState { return true }
        return false
    }

    var feedbackTitle: String {
        switch answerState {
        case .correct: "Correct!"
        case .timedOut: "Time is up"
        default: "Not quite"
        }
    }

    var feedbackMessage: String {
        switch answerState {
        case .correct:
            "Nice work. The ice is getting thinner."
        case .timedOut:
            "The correct answer was \(currentQuestion.answers[currentQuestion.correctIndex])."
        case .incorrect:
            "The correct answer was \(currentQuestion.answers[currentQuestion.correctIndex])."
        case .unanswered:
            ""
        }
    }

    func answer(_ index: Int) {
        guard answerState == .unanswered else { return }
        stopTimer()
        if index == currentQuestion.correctIndex {
            score += 1
            answerState = .correct(selected: index)
        } else {
            answerState = .incorrect(selected: index, correct: currentQuestion.correctIndex)
        }
    }

    func advance() {
        if isLastQuestion {
            isFinished = true
            stopTimer()
        } else {
            questionIndex += 1
            secondsRemaining = 30
            answerState = .unanswered
            startTimer()
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    func commitResultIfNeeded(in appState: AppState) -> RewardBonus? {
        if !didCommit {
            committedReward = appState.completeQuiz(score: score)
            didCommit = true
        }
        return committedReward
    }

    private func startTimer() {
        stopTimer()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled, self.answerState == .unanswered else { return }
                if self.secondsRemaining > 1 {
                    self.secondsRemaining -= 1
                } else {
                    self.secondsRemaining = 0
                    self.answerState = .timedOut(correct: self.currentQuestion.correctIndex)
                    return
                }
            }
        }
    }
}
