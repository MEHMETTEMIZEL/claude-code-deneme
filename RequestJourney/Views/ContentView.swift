import SwiftUI

struct ContentView: View {
    @State private var player = JourneyPlayer()
    @AppStorage("didSeeIntro") private var didSeeIntro = false

    var body: some View {
        TabView {
            JourneyView(player: player)
                .tabItem { Label("Yolculuk", systemImage: "arrow.up.arrow.down") }

            MemoryPalaceView()
                .tabItem { Label("Hafıza Sarayı", systemImage: "building.2") }

            LatencyView()
                .tabItem { Label("Zamanlama", systemImage: "chart.bar.xaxis") }

            QuizView()
                .tabItem { Label("Test", systemImage: "checkmark.seal") }
        }
        .sheet(isPresented: Binding(get: { !didSeeIntro }, set: { didSeeIntro = !$0 })) {
            IntroView { didSeeIntro = true }
                .interactiveDismissDisabled()
        }
    }
}

/// İlk açılışta görünen "nasıl öğrenirsin" ekranı.
struct IntroView: View {
    var onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("✉️ → 🗄️ → 📦")
                    .font(.system(size: 44))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)

                Text("Bir isteğin yolculuğu")
                    .font(.largeTitle.bold())

                Text("Bir butona dokunduğunda, cevap ekrana gelene kadar 12 kattan oluşan bir kuleden aşağı inip geri çıkarsın. Bu uygulama o yolculuğu sahne sahne gösterir.")
                    .font(.body)

                tip("arrow.up.arrow.down", "Yolculuk", "Mektubun (✉️) kulenin içinde aşağı inişini, cevabın (📦) yukarı çıkışını izle. Oynat'a bas ya da adımları kaydır.")
                tip("building.2", "Hafıza Sarayı", "Her kata bir sahne bağlandı: kapı zili, postane, otoyol, kütüphane… Görsel hafızan bu sahneleri hatırlar, teknik detay sahnenin üstüne oturur.")
                tip("chart.bar.xaxis", "Zamanlama", "Sürenin nerede harcandığını gör. Bağlantıyı yeniden kullanınca neyin kaybolduğunu keşfet.")
                tip("checkmark.seal", "Test", "Katmanları sıraya diz, olayları katmanlarıyla eşleştir.")

                Text("🌈 İpucu: Renkler gökkuşağı sırasında. Mor çatıdan kırmızı bodruma iniyorsun.")
                    .font(.callout)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.purple.opacity(0.1)))

                Button(action: onStart) {
                    Text("Yolculuğa başla")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
        }
    }

    private func tip(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
