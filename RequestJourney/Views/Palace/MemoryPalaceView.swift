import SwiftUI

/// Hafıza sarayı: her katman bir binanın katı, her kat bir sahne.
struct MemoryPalaceView: View {
    @State private var selected: Layer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    intro
                    ForEach(Side.allCases) { side in
                        building(side)
                    }
                    storyChain
                    rainbowCard
                }
                .padding()
            }
            .navigationTitle("Hafıza Sarayı")
            .sheet(item: $selected) { layer in
                LayerDetailSheet(layer: layer)
            }
        }
    }

    private var intro: some View {
        Text("Bir mektup gökdelenin çatısından yola çıkar, otoyoldan geçip karşıdaki binanın bodrumuna kadar iner; sonra cevapla aynı yoldan geri döner. Her kata dokun, sahneyi gözünün önüne getir.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private func building(_ side: Side) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(side.emoji) \(side.title.uppercased(with: Locale(identifier: "tr_TR")))")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                if side != .network {
                    RoofShape()
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 22)
                        .padding(.horizontal, 30)
                }
                VStack(spacing: 4) {
                    ForEach(Layer.allCases.filter { $0.side == side }) { layer in
                        floor(layer)
                    }
                }
                .padding(side == .network ? 0 : 6)
                .background(
                    RoundedRectangle(cornerRadius: side == .network ? 0 : 10)
                        .fill(side == .network ? Color.clear : Color(.tertiarySystemFill))
                )
            }
        }
    }

    private func floor(_ layer: Layer) -> some View {
        Button {
            selected = layer
        } label: {
            HStack(spacing: 12) {
                Text("\(layer.rawValue + 1)")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(layer.color)
                    .frame(width: 20)

                Text(layer.emoji)
                    .font(.system(size: 30))
                    .frame(width: 48, height: 48)
                    .background(RoundedRectangle(cornerRadius: 8).fill(layer.color.opacity(0.25)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(layer.color, lineWidth: 2))

                VStack(alignment: .leading, spacing: 2) {
                    Text(layer.metaphor)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(layer.title)
                        .font(.subheadline)
                        .foregroundStyle(layer.color)
                    Text(layer.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
            )
            .overlay(alignment: .leading) {
                UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 10)
                    .fill(layer.color)
                    .frame(width: 5)
            }
            .overlay {
                if layer.side == .network {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.secondary.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [10, 6]))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var storyChain: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tek cümlelik hikâye")
                .font(.headline)
            Text("Bu zinciri bir kez gözünde canlandır; katmanların sırası kendiliğinden gelir.")
                .font(.caption)
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 6) {
                ForEach(Layer.allCases) { layer in
                    HStack(spacing: 4) {
                        Text("\(layer.emoji) \(storyVerb(layer))")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(layer.color.opacity(0.2)))
                        if layer != Layer.allCases.last {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
    }

    private var rainbowCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🌈 Gökkuşağı kuralı")
                .font(.headline)
            LinearGradient(colors: Layer.allCases.map(\.color), startPoint: .leading, endPoint: .trailing)
                .frame(height: 14)
                .clipShape(Capsule())
            Text("Mor çatıdan kırmızı bodruma. Renk ne kadar sıcaksa, veriye o kadar yakınsın; ne kadar soğuksa, kullanıcıya o kadar yakınsın.")
                .font(.subheadline)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
    }

    private func storyVerb(_ layer: Layer) -> String {
        switch layer {
        case .ui: "Zili çal"
        case .app: "mektubu yaz"
        case .framework: "postaneye ver"
        case .kernel: "banda diz"
        case .physical: "telsizle yayınla"
        case .internet: "otoyola çık"
        case .edge: "gümrükten geç"
        case .serverOS: "posta odasına bırak"
        case .backend: "memura ulaş"
        case .cache: "nota bak"
        case .database: "kütüphaneye in"
        case .storage: "depodan al"
        }
    }
}

struct RoofShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct LayerDetailSheet: View {
    let layer: Layer
    @Environment(\.dismiss) private var dismiss

    private var steps: [JourneyStep] {
        JourneyData.steps.filter { $0.layer == layer }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(spacing: 8) {
                        Text(layer.emoji)
                            .font(.system(size: 80))
                        Text(layer.metaphor)
                            .font(.title2.bold())
                        LayerChip(layer: layer)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .background(RoundedRectangle(cornerRadius: 20).fill(layer.color.opacity(0.15)))

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Sahne", systemImage: "eye")
                            .font(.headline)
                        Text(layer.palaceStory)
                            .font(.body)
                            .italic()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Gerçekte", systemImage: "cpu")
                            .font(.headline)
                        Text(layer.summary)
                        Text(layer.subtitle)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Bu kattaki adımlar", systemImage: "list.number")
                            .font(.headline)
                        ForEach(steps) { step in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("\(step.number).")
                                        .font(.subheadline.bold().monospacedDigit())
                                        .foregroundStyle(layer.color)
                                    Text(step.title)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    DirectionBadge(direction: step.direction)
                                }
                                Text(.init(step.summary))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(layer.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
