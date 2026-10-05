import SwiftUI

struct JourneyView: View {
    @Bindable var player: JourneyPlayer
    @State private var showStepList = false
    @State private var towerExpanded = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal)
                    .padding(.top, 4)

                Group {
                    if towerExpanded {
                        LayerTowerView(
                            currentLayer: player.current.layer,
                            direction: player.current.direction,
                            onSelect: { player.jump(toLayer: $0) }
                        )
                    } else {
                        MiniTowerView(currentLayer: player.current.layer, direction: player.current.direction)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)

                Divider()

                ScrollView {
                    StepDetailView(step: player.current, total: player.steps.count)
                        .padding()
                }
                .id(player.index)
                .transition(.opacity)
                .simultaneousGesture(swipeGesture)

                Divider()
                controls
            }
            .navigationTitle("İsteğin Yolculuğu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.snappy) { towerExpanded.toggle() }
                    } label: {
                        Image(systemName: towerExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                    }
                    .accessibilityLabel(towerExpanded ? "Kuleyi küçült" : "Kuleyi büyüt")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showStepList = true } label: {
                        Image(systemName: "list.number")
                    }
                    .accessibilityLabel("Tüm adımlar")
                }
            }
            .sheet(isPresented: $showStepList) {
                StepListView(player: player)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(JourneyData.scenario)
                    .font(.system(.caption, design: .monospaced).bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Text("\(player.current.number)/\(player.steps.count)")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: player.progress)
                .tint(player.current.layer.color)
            HStack(spacing: 4) {
                Text("✉️ istek aşağı iner")
                Text("·")
                Text("📦 yanıt yukarı çıkar")
                Spacer()
                Text("Kata dokun → atla")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 26) {
            Button { player.reset() } label: {
                Image(systemName: "backward.end.fill")
            }
            .disabled(player.isFirst)
            .accessibilityLabel("Başa dön")

            Button {
                player.pause()
                player.previous()
            } label: {
                Image(systemName: "backward.fill")
            }
            .disabled(player.isFirst)
            .accessibilityLabel("Önceki adım")

            Button { player.togglePlay() } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(player.current.layer.color)
            }
            .accessibilityLabel(player.isPlaying ? "Duraklat" : "Oynat")

            Button {
                player.pause()
                player.next()
            } label: {
                Image(systemName: "forward.fill")
            }
            .disabled(player.isLast)
            .accessibilityLabel("Sonraki adım")

            Menu {
                Picker("Hız", selection: $player.speed) {
                    Text("Yavaş (0.5×)").tag(0.5)
                    Text("Normal (1×)").tag(1.0)
                    Text("Hızlı (2×)").tag(2.0)
                }
            } label: {
                Text(player.speed == 0.5 ? "0.5×" : player.speed == 2 ? "2×" : "1×")
                    .font(.subheadline.bold().monospacedDigit())
                    .frame(width: 36)
            }
            .accessibilityLabel("Oynatma hızı")
        }
        .font(.title2)
        .padding(.vertical, 6)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let dx = value.translation.width
                guard abs(dx) > abs(value.translation.height) * 1.5, abs(dx) > 60 else { return }
                player.pause()
                if dx < 0 { player.next() } else { player.previous() }
            }
    }
}

struct StepDetailView: View {
    let step: JourneyStep
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                LayerChip(layer: step.layer)
                DirectionBadge(direction: step.direction)
                Spacer()
                Label("~\(step.durationText)", systemImage: "stopwatch")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("ADIM \(step.number)")
                    .font(.caption.bold())
                    .foregroundStyle(step.layer.color)
                Text(step.title)
                    .font(.title2.bold())
                Text(.init(step.summary))
                    .font(.body)
            }

            if let visual = step.visual {
                StepVisualView(visual: visual, tint: step.layer.color)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Neler oluyor?")
                    .font(.headline)
                ForEach(step.details, id: \.self) { detail in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 7))
                            .foregroundStyle(step.layer.color)
                        Text(.init(detail))
                            .font(.subheadline)
                    }
                }
            }

            if let payload = step.payload {
                PayloadView(text: payload)
            }

            MemoryHookView(layer: step.layer, text: step.memoryHook)

            if step.skippedOnReuse {
                Label("Açık bir bağlantı yeniden kullanılırsa (keep-alive) bu adım tamamen atlanır.", systemImage: "arrow.triangle.2.circlepath")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct StepListView: View {
    let player: JourneyPlayer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                section(.request, title: "✉️ İstek — aşağı iniş")
                section(.response, title: "📦 Yanıt — yukarı çıkış")
            }
            .navigationTitle("Tüm adımlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private func section(_ direction: Direction, title: String) -> some View {
        Section(title) {
            ForEach(player.steps.filter { $0.direction == direction }) { step in
                Button {
                    player.jump(to: step.id)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text("\(step.number)")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(step.layer.color))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.subheadline.weight(step.id == player.index ? .bold : .regular))
                                .foregroundStyle(.primary)
                            Text("\(step.layer.emoji) \(step.layer.title)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if step.id == player.index {
                            Image(systemName: "location.fill")
                                .foregroundStyle(step.layer.color)
                        }
                    }
                }
            }
        }
    }
}
