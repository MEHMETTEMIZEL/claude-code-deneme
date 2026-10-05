import SwiftUI

/// 12 katlı kule: sol şeritte ✉️ iner (istek), sağ şeritte 📦 çıkar (yanıt).
struct LayerTowerView: View {
    let currentLayer: Layer
    let direction: Direction
    var onSelect: (Layer) -> Void = { _ in }

    private let rowHeight: CGFloat = 20
    private let spacing: CGFloat = 2
    private let layers = Layer.allCases

    private var totalHeight: CGFloat {
        CGFloat(layers.count) * rowHeight + CGFloat(layers.count - 1) * spacing
    }

    private func yOffset(_ layer: Layer) -> CGFloat {
        CGFloat(layer.rawValue) * (rowHeight + spacing)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            sideColumn
            lane(.request)
            VStack(spacing: spacing) {
                ForEach(layers) { layer in
                    band(layer)
                }
            }
            lane(.response)
        }
        .frame(height: totalHeight)
    }

    /// Solda 📱 / 🌐 / 🖥️ bölgeleri.
    private var sideColumn: some View {
        VStack(spacing: spacing) {
            ForEach(Side.allCases) { side in
                let count = layers.filter { $0.side == side }.count
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 24, height: CGFloat(count) * rowHeight + CGFloat(count - 1) * spacing)
                    .overlay(Text(side.emoji).font(.system(size: 13)))
            }
        }
    }

    private func lane(_ laneDirection: Direction) -> some View {
        let center = yOffset(currentLayer) + rowHeight / 2
        let isActive = laneDirection == direction
        let trailTop: CGFloat = laneDirection == .request ? 0 : center
        let trailHeight: CGFloat = laneDirection == .request ? center : totalHeight - center

        return ZStack(alignment: .top) {
            Capsule()
                .fill(laneDirection.color.opacity(0.15))
                .frame(width: 4, height: totalHeight)

            if isActive {
                Capsule()
                    .fill(laneDirection.color.opacity(0.75))
                    .frame(width: 4, height: max(trailHeight, 0))
                    .offset(y: trailTop)

                Text(laneDirection.packet)
                    .font(.system(size: 15))
                    .frame(height: rowHeight)
                    .offset(y: yOffset(currentLayer))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 22, height: totalHeight, alignment: .top)
    }

    private func band(_ layer: Layer) -> some View {
        let isCurrent = layer == currentLayer

        return Button {
            onSelect(layer)
        } label: {
            HStack(spacing: 6) {
                Text(layer.emoji)
                    .font(.system(size: 11))
                Text(layer.title)
                    .font(.system(size: 12, weight: isCurrent ? .bold : .medium))
                    .lineLimit(1)
                Spacer(minLength: 4)
                if isCurrent {
                    Text(layer.subtitle)
                        .font(.system(size: 9, weight: .medium))
                        .lineLimit(1)
                        .opacity(0.9)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: rowHeight)
            .foregroundStyle(isCurrent ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(layer.color.opacity(isCurrent ? 1 : 0.22))
            )
            .scaleEffect(isCurrent ? 1.04 : 1)
            .shadow(color: isCurrent ? layer.color.opacity(0.5) : .clear, radius: 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .zIndex(isCurrent ? 1 : 0)
    }
}

/// Kule katlandığında kullanılan tek satırlık şerit.
struct MiniTowerView: View {
    let currentLayer: Layer
    let direction: Direction

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Layer.allCases) { layer in
                let isCurrent = layer == currentLayer
                RoundedRectangle(cornerRadius: 4)
                    .fill(layer.color.opacity(isCurrent ? 1 : 0.3))
                    .frame(height: 26)
                    .frame(maxWidth: isCurrent ? 60 : .infinity)
                    .overlay {
                        if isCurrent {
                            Text(direction.packet).font(.system(size: 14))
                        }
                    }
            }
        }
    }
}

#Preview {
    LayerTowerView(currentLayer: .kernel, direction: .request)
        .padding()
}
