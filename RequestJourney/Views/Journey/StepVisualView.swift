import SwiftUI

struct StepVisualView: View {
    let visual: StepVisual
    let tint: Color

    var body: some View {
        Group {
            switch visual {
            case .pipeline(let items):
                PipelineView(items: items, tint: tint)
            case .handshake(let messages):
                HandshakeView(messages: messages)
            case .nested(let labels):
                NestedBoxesView(labels: labels)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
    }
}

/// Aşamalar zinciri; vurgu sırayla soldan sağa akar.
struct PipelineView: View {
    let items: [String]
    let tint: Color

    private let tick = 0.7

    var body: some View {
        TimelineView(.periodic(from: .now, by: tick)) { context in
            let active = Int(context.date.timeIntervalSinceReferenceDate / tick) % max(items.count, 1)
            FlowLayout(spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 4) {
                        Text(item)
                            .font(.caption.weight(index == active ? .bold : .regular))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .foregroundStyle(index == active ? Color.white : Color.primary)
                            .background(Capsule().fill(tint.opacity(index == active ? 1 : 0.18)))
                            .scaleEffect(index == active ? 1.08 : 1)
                        if index < items.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: active)
        }
    }
}

/// iPhone ↔ sunucu mesajlaşması; oklar tek tek belirir.
struct HandshakeView: View {
    let messages: [HandshakeMessage]
    @State private var visibleCount = 0

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("iPhone", systemImage: "iphone")
                Spacer()
                Label("Sunucu", systemImage: "server.rack")
            }
            .font(.caption.bold())

            ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                let color: Color = message.fromClient ? .blue : .green
                VStack(spacing: 2) {
                    Text(message.label)
                        .font(.system(.caption2, design: .monospaced).bold())
                        .foregroundStyle(color)
                        .frame(maxWidth: .infinity, alignment: message.fromClient ? .leading : .trailing)
                    ArrowShape(leftToRight: message.fromClient)
                        .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(height: 10)
                }
                .opacity(index < visibleCount ? 1 : 0.12)
                .offset(x: index < visibleCount ? 0 : (message.fromClient ? -20 : 20))
            }
        }
        .padding(.horizontal, 4)
        .task {
            visibleCount = 0
            for index in messages.indices {
                try? await Task.sleep(for: .milliseconds(550))
                withAnimation(.easeOut(duration: 0.35)) { visibleCount = index + 1 }
            }
        }
    }
}

struct ArrowShape: Shape {
    var leftToRight: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y = rect.midY
        let start = leftToRight ? rect.minX : rect.maxX
        let end = leftToRight ? rect.maxX : rect.minX
        let head: CGFloat = leftToRight ? -8 : 8
        path.move(to: CGPoint(x: start, y: y))
        path.addLine(to: CGPoint(x: end, y: y))
        path.move(to: CGPoint(x: end + head, y: y - 5))
        path.addLine(to: CGPoint(x: end, y: y))
        path.addLine(to: CGPoint(x: end + head, y: y + 5))
        return path
    }
}

/// Matruşka gibi iç içe kutular (kapsülleme).
struct NestedBoxesView: View {
    let labels: [String]

    var body: some View {
        box(level: 0)
    }

    private func box(level: Int) -> AnyView {
        let color = Color(hue: 0.08 + Double(level) * 0.14, saturation: 0.7, brightness: 0.8)
        return AnyView(
            VStack(alignment: .leading, spacing: 4) {
                Text(labels[level])
                    .font(.caption2.bold())
                    .foregroundStyle(color)
                if level + 1 < labels.count {
                    box(level: level + 1)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.10)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 1.5))
        )
    }
}
