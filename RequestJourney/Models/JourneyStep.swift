import SwiftUI

enum Direction {
    case request, response

    var title: String { self == .request ? "İSTEK" : "YANIT" }
    var arrowIcon: String { self == .request ? "arrow.down" : "arrow.up" }
    var packet: String { self == .request ? "✉️" : "📦" }
    var color: Color { self == .request ? .blue : .green }
}

struct HandshakeMessage {
    let fromClient: Bool
    let label: String
}

/// Adımın altında çizilecek küçük görsel diyagram.
enum StepVisual {
    /// Soldan sağa akan aşamalar zinciri.
    case pipeline([String])
    /// iPhone ile sunucu arasında gidip gelen mesajlar.
    case handshake([HandshakeMessage])
    /// İç içe zarflar (kapsülleme), dıştan içe.
    case nested([String])
}

struct JourneyStep: Identifiable {
    var id: Int = 0
    let layer: Layer
    let direction: Direction
    let title: String
    let summary: String
    let details: [String]
    let memoryHook: String
    var payload: String? = nil
    var visual: StepVisual? = nil
    let durationMs: Double
    /// Açık bir bağlantı (keep-alive) yeniden kullanılırsa bu adım hiç yaşanmaz.
    var skippedOnReuse: Bool = false

    var number: Int { id + 1 }

    var durationText: String { Self.format(ms: durationMs) }

    static func format(ms: Double) -> String {
        if ms == 0 { return "0 ms" }
        if ms < 1 { return String(format: "%.2f ms", ms) }
        if ms.rounded() == ms { return "\(Int(ms)) ms" }
        return String(format: "%.1f ms", ms)
    }
}
