import SwiftUI

struct LayerChip: View {
    let layer: Layer

    var body: some View {
        Label(layer.title, systemImage: layer.icon)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(layer.color))
    }
}

struct DirectionBadge: View {
    let direction: Direction

    var body: some View {
        Label(direction.title, systemImage: direction.arrowIcon)
            .font(.caption2.bold())
            .foregroundStyle(direction.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().stroke(direction.color, lineWidth: 1.5))
    }
}

/// Görsel hafızaya çakılan benzetme kutusu.
struct MemoryHookView: View {
    let layer: Layer
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(layer.emoji)
                .font(.system(size: 40))
            VStack(alignment: .leading, spacing: 4) {
                Text("🧠 HAFIZA ÇİVİSİ · \(layer.metaphor.uppercased(with: Locale(identifier: "tr_TR")))")
                    .font(.caption2.bold())
                    .foregroundStyle(layer.color)
                Text(text)
                    .font(.callout)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(layer.color.opacity(0.12)))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(layer.color.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        )
    }
}

/// O anda verinin neye benzediğini gösteren terminal görünümlü kutu.
struct PayloadView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Bu anda veri neye benziyor?", systemImage: "terminal")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(red: 0.55, green: 0.95, blue: 0.6))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(12)
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
        }
    }
}

/// Satır taşınca alt satıra geçen basit akış yerleşimi.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var width: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            width = max(width, x - spacing)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Yanlış cevapta sallanma efekti.
struct Shake: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(animatableData * .pi * 4), y: 0))
    }
}
