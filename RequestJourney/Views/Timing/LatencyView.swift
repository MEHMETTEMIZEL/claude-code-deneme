import SwiftUI

/// Sürenin nerede harcandığını gösteren şelale (waterfall) ve katman dağılımı.
struct LatencyView: View {
    @State private var reuseConnection = false

    private struct LayerTotal: Identifiable {
        let layer: Layer
        let ms: Double
        var id: Int { layer.rawValue }
    }

    private struct WaterfallItem: Identifiable {
        let step: JourneyStep
        let start: Double
        let ms: Double
        var id: Int { step.id }
    }

    private func duration(_ step: JourneyStep) -> Double {
        reuseConnection && step.skippedOnReuse ? 0 : step.durationMs
    }

    private var total: Double {
        JourneyData.steps.reduce(0) { $0 + duration($1) }
    }

    private var layerTotals: [LayerTotal] {
        Layer.allCases.map { layer in
            LayerTotal(layer: layer, ms: JourneyData.steps.filter { $0.layer == layer }.reduce(0) { $0 + duration($1) })
        }
    }

    private var waterfall: [WaterfallItem] {
        var start = 0.0
        return JourneyData.steps.map { step in
            let ms = duration(step)
            defer { start += ms }
            return WaterfallItem(step: step, start: start, ms: ms)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Toplam süre")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("~\(Int(total.rounded())) ms")
                            .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                            .contentTransition(.numericText())
                        Text("Dokunuştan pikselin değişmesine kadar. Göz ~100 ms altını 'anlık' algılar.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Toggle(isOn: $reuseConnection.animation(.snappy)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bağlantıyı yeniden kullan")
                            Text("İkinci istek: DNS + TCP + TLS atlanır (keep-alive)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Süre hangi katta harcanıyor?") {
                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            ForEach(layerTotals.filter { $0.ms > 0 }) { item in
                                Rectangle()
                                    .fill(item.layer.color)
                                    .frame(width: geo.size.width * item.ms / max(total, 1))
                            }
                        }
                    }
                    .frame(height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

                    ForEach(layerTotals.sorted { $0.ms > $1.ms }) { item in
                        HStack {
                            Circle().fill(item.layer.color).frame(width: 10, height: 10)
                            Text("\(item.layer.emoji) \(item.layer.title)")
                                .font(.subheadline)
                            Spacer()
                            Text(JourneyStep.format(ms: item.ms))
                                .font(.subheadline.monospacedDigit())
                            Text(verbatim: "%\(Int((item.ms / max(total, 1) * 100).rounded()))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                        .opacity(item.ms == 0 ? 0.4 : 1)
                    }
                }

                Section("Şelale: adımlar zaman çizgisinde") {
                    ForEach(waterfall) { item in
                        waterfallRow(item)
                    }
                }

                Section("📌 Akılda kalsın") {
                    insight("🛣️", "Asıl maliyet mesafe", "Işık hızı sınırı yüzünden her gidiş-dönüş (RTT) onlarca milisaniye tutar. Sunucu ve veritabanı ise çoğunlukla birkaç milisaniyede işini bitirir.")
                    insight("🤝", "İlk istek pahalıdır", "DNS + TCP + TLS = cevaptan önce 3 ekstra tur. Bu yüzden bağlantılar açık tutulur ve HTTP/2 tek bağlantıda çok istek taşır. HTTP/3 (QUIC) TCP ve TLS'i tek tura indirir.")
                    insight("📚", "Ama veritabanı da patlayabilir", "Buradaki 1,5 ms indeks sayesinde. İndeks olmasaydı milyonlarca satır taranır, aynı sorgu saniyeler sürebilirdi.")
                    insight("🔔", "Çizim de zamana dahil", "Ekranı çizmek (~16 ms) ve dokunuşu algılamak (~8 ms) toplamın küçümsenmeyecek bir parçası.")
                }

                Section {
                    Text("Süreler temsilidir: Wi-Fi üzerinde, ~25 ms gidiş-dönüş süresi, sıcak bir sunucu ve küçük bir sorgu varsayılmıştır.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Zamanlama")
        }
    }

    private func waterfallRow(_ item: WaterfallItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("\(item.step.number)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: 20, alignment: .trailing)
                Text(item.step.layer.emoji)
                Text(item.step.title)
                    .lineLimit(1)
                Spacer()
                Text(JourneyStep.format(ms: item.ms))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            GeometryReader { geo in
                let scale = geo.size.width / max(total, 1)
                let width = max(3, item.ms * scale)
                Capsule()
                    .fill(item.step.layer.color)
                    .frame(width: width, height: 6)
                    .offset(x: min(item.start * scale, geo.size.width - width))
            }
            .frame(height: 6)
        }
        .opacity(item.ms == 0 ? 0.3 : 1)
    }

    private func insight(_ emoji: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(text).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
