import SwiftUI

struct QuizView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case order = "Katman Sırası"
        case which = "Hangi Katman?"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .order

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mod", selection: $mode) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch mode {
                case .order: OrderGameView()
                case .which: WhichLayerGameView()
                }
            }
            .navigationTitle("Kendini Test Et")
        }
    }
}

/// Karışık katmanları en üstten en alta doğru sırayla seç.
struct OrderGameView: View {
    @State private var pool: [Layer] = Layer.allCases.shuffled()
    @State private var placed: [Layer] = []
    @State private var mistakes = 0
    @State private var wrongLayer: Layer?

    private var isDone: Bool { placed.count == Layer.allCases.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Kuleyi yeniden inşa et: katmanları en üstten (dokunuş) en alta (disk) doğru sırayla seç.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 3) {
                    ForEach(0..<Layer.allCases.count, id: \.self) { index in
                        if index < placed.count {
                            placedRow(placed[index])
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            emptyRow(index)
                        }
                    }
                }

                if isDone {
                    result
                } else {
                    HStack {
                        Text("Sıradaki kat hangisi?")
                            .font(.headline)
                        Spacer()
                        Text("Hata: \(mistakes)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(mistakes == 0 ? Color.secondary : Color.red)
                    }
                    FlowLayout(spacing: 8) {
                        ForEach(pool) { layer in
                            chip(layer)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func placedRow(_ layer: Layer) -> some View {
        HStack(spacing: 8) {
            Text("\(layer.rawValue + 1)")
                .font(.caption2.bold().monospacedDigit())
                .frame(width: 18)
            Text(layer.emoji)
            Text(layer.title)
                .font(.caption.bold())
            Spacer()
            Text(layer.metaphor)
                .font(.caption2)
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(RoundedRectangle(cornerRadius: 6).fill(layer.color))
    }

    private func emptyRow(_ index: Int) -> some View {
        HStack {
            Text("\(index + 1)")
                .font(.caption2.monospacedDigit())
                .frame(width: 18)
            Spacer()
        }
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
    }

    private func chip(_ layer: Layer) -> some View {
        let isWrong = wrongLayer == layer
        return Button {
            tap(layer)
        } label: {
            Text("\(layer.emoji) \(layer.title)")
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(isWrong ? Color.white : Color.primary)
                .background(Capsule().fill(isWrong ? Color.red : Color(.secondarySystemBackground)))
                .overlay(Capsule().stroke(isWrong ? Color.red : Color.secondary.opacity(0.3)))
        }
        .buttonStyle(.plain)
        .modifier(Shake(animatableData: isWrong ? 1 : 0))
    }

    private var result: some View {
        VStack(spacing: 12) {
            Text(mistakes == 0 ? "🏆" : "🎉")
                .font(.system(size: 60))
            Text(mistakes == 0 ? "Kusursuz! Kule zihnine kazındı." : "Tamamlandı! \(mistakes) hata yaptın.")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("🔔 ✍️ 🏤 🚚 📻 🛣️ 🛂 📬 🧑‍💼 🗒️ 📚 🗄️")
                .font(.title3)
            Button("Tekrar oyna") { restart() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private func tap(_ layer: Layer) {
        if layer.rawValue == placed.count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                placed.append(layer)
                pool.removeAll { $0 == layer }
                wrongLayer = nil
            }
        } else {
            mistakes += 1
            wrongLayer = nil
            withAnimation(.linear(duration: 0.4)) { wrongLayer = layer }
            Task {
                try? await Task.sleep(for: .milliseconds(700))
                // Animasyonsuz geri dönüş: ikinci bir sallanma olmasın.
                if wrongLayer == layer { wrongLayer = nil }
            }
        }
    }

    private func restart() {
        withAnimation {
            pool = Layer.allCases.shuffled()
            placed = []
            mistakes = 0
            wrongLayer = nil
        }
    }
}

/// Bir olay gösterilir, hangi katmanda yaşandığı sorulur.
struct WhichLayerGameView: View {
    @State private var question: JourneyStep = JourneyData.steps.randomElement()!
    @State private var options: [Layer] = []
    @State private var answer: Layer?
    @State private var score = 0
    @State private var asked = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Skor: \(score)/\(asked)")
                        .font(.headline.monospacedDigit())
                    Spacer()
                    DirectionBadge(direction: question.direction)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bu olay hangi katmanda gerçekleşir?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(question.title)
                        .font(.title3.bold())
                    if answer != nil {
                        Text(.init(question.summary))
                            .font(.subheadline)
                            .transition(.opacity)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))

                ForEach(options) { layer in
                    optionButton(layer)
                }

                if answer != nil {
                    MemoryHookView(layer: question.layer, text: question.memoryHook)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    Button {
                        nextQuestion()
                    } label: {
                        Text("Sonraki soru")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onAppear {
            if options.isEmpty { makeOptions() }
        }
    }

    private func optionButton(_ layer: Layer) -> some View {
        let isCorrect = layer == question.layer
        let isChosen = layer == answer
        let revealed = answer != nil

        let fill: Color = !revealed ? Color(.secondarySystemBackground)
            : isCorrect ? .green.opacity(0.25)
            : isChosen ? .red.opacity(0.25)
            : Color(.secondarySystemBackground)

        return Button {
            guard answer == nil else { return }
            withAnimation(.snappy) {
                answer = layer
                asked += 1
                if isCorrect { score += 1 }
            }
        } label: {
            HStack(spacing: 12) {
                Text(layer.emoji)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(layer.title)
                        .font(.subheadline.bold())
                    Text(layer.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if revealed && isCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                } else if revealed && isChosen {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(fill))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(layer.color.opacity(revealed && !isCorrect && !isChosen ? 0.2 : 0.8), lineWidth: 1.5)
            )
            .opacity(revealed && !isCorrect && !isChosen ? 0.5 : 1)
        }
        .buttonStyle(.plain)
    }

    private func makeOptions() {
        let others = Layer.allCases.filter { $0 != question.layer }.shuffled().prefix(3)
        options = (Array(others) + [question.layer]).shuffled()
    }

    private func nextQuestion() {
        var next = JourneyData.steps.randomElement()!
        while next.id == question.id {
            next = JourneyData.steps.randomElement()!
        }
        withAnimation(.snappy) {
            question = next
            answer = nil
            makeOptions()
        }
    }
}
