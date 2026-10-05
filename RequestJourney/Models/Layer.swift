import SwiftUI

/// Bir isteğin geçtiği katmanlar — en üstten (dokunuş) en alta (disk).
/// Renkler gökkuşağı sırasıyla verilir: mor çatıdan kırmızı bodruma.
enum Layer: Int, CaseIterable, Identifiable {
    case ui, app, framework, kernel, physical, internet, edge, serverOS, backend, cache, database, storage

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .ui: "Arayüz"
        case .app: "Uygulama Kodu"
        case .framework: "iOS Ağ Çatısı"
        case .kernel: "iOS Çekirdeği"
        case .physical: "Donanım & Radyo"
        case .internet: "İnternet"
        case .edge: "Kenar Katmanı"
        case .serverOS: "Sunucu Çekirdeği"
        case .backend: "Sunucu Uygulaması"
        case .cache: "Önbellek"
        case .database: "Veritabanı"
        case .storage: "Depolama"
        }
    }

    var subtitle: String {
        switch self {
        case .ui: "SwiftUI · UIKit · Dokunmatik"
        case .app: "Swift · ViewModel · async/await"
        case .framework: "URLSession · DNS · TLS · HTTP/2"
        case .kernel: "XNU · Soket · TCP/IP"
        case .physical: "Wi-Fi · 5G · Anten"
        case .internet: "Modem · İSS · BGP · Fiber"
        case .edge: "CDN · WAF · Yük Dengeleyici"
        case .serverOS: "Linux · NIC · epoll"
        case .backend: "Router · Middleware · İş mantığı"
        case .cache: "Redis · Bellek içi"
        case .database: "PostgreSQL · SQL · İndeks"
        case .storage: "Tampon · Sayfa önbelleği · SSD"
        }
    }

    var icon: String {
        switch self {
        case .ui: "hand.tap"
        case .app: "chevron.left.forwardslash.chevron.right"
        case .framework: "square.stack.3d.up"
        case .kernel: "cpu"
        case .physical: "antenna.radiowaves.left.and.right"
        case .internet: "globe.europe.africa"
        case .edge: "arrow.triangle.branch"
        case .serverOS: "terminal"
        case .backend: "gearshape.2"
        case .cache: "bolt.fill"
        case .database: "cylinder.split.1x2"
        case .storage: "internaldrive"
        }
    }

    /// Hafıza sarayındaki görsel benzetme.
    var emoji: String {
        switch self {
        case .ui: "🔔"
        case .app: "✍️"
        case .framework: "🏤"
        case .kernel: "🚚"
        case .physical: "📻"
        case .internet: "🛣️"
        case .edge: "🛂"
        case .serverOS: "📬"
        case .backend: "🧑‍💼"
        case .cache: "🗒️"
        case .database: "📚"
        case .storage: "🗄️"
        }
    }

    var metaphor: String {
        switch self {
        case .ui: "Çatıdaki kapı zili"
        case .app: "Mektubu yazan sen"
        case .framework: "Postane gişesi"
        case .kernel: "Postanenin sıralama deposu"
        case .physical: "Telsiz"
        case .internet: "Otoyollar ve kavşaklar"
        case .edge: "Gümrük ve resepsiyon"
        case .serverOS: "Binanın posta odası"
        case .backend: "Memurun masası"
        case .cache: "Masadaki yapışkan not"
        case .database: "Kütüphane ve kütüphaneci"
        case .storage: "Bodrumdaki depo"
        }
    }

    var summary: String {
        switch self {
        case .ui: "Kullanıcının gördüğü ve dokunduğu her şey. Yolculuk burada başlar ve burada biter."
        case .app: "Senin yazdığın mantık: isteği oluşturur, cevabı modele çevirir, ekran durumunu (state) yönetir."
        case .framework: "Apple'ın sistem kütüphaneleri. Önbellek, isim çözme (DNS), şifreleme (TLS) ve HTTP protokolü kullanıcı alanında burada yürür."
        case .kernel: "İşletim sisteminin kalbi. Soketleri, TCP'nin güvenilirliğini ve IP yönlendirmesini yönetir. Uygulama buraya sadece sistem çağrısıyla ulaşabilir."
        case .physical: "Bitlerin fiziksel sinyale — radyo dalgasına, ışığa, elektriğe — dönüştüğü yer."
        case .internet: "Binlerce bağımsız ağın (İSS'ler, bulut sağlayıcıları) birbirine bağlandığı küresel yol ağı."
        case .edge: "Sunucuların önündeki kalkan ve trafik polisi: CDN, güvenlik duvarı, TLS sonlandırma ve yük dengeleme."
        case .serverOS: "Sunucu makinenin işletim sistemi (genelde Linux). Paketleri açıp doğru uygulamanın soketine teslim eder."
        case .backend: "API'nin kodu: kimliği doğrular, iş kurallarını uygular, veriyi toplar ve yanıtı üretir."
        case .cache: "Sık istenen veriyi RAM'de tutarak veritabanını korur ve cevapları hızlandırır."
        case .database: "Verinin kalıcı ve tutarlı şekilde saklandığı, SQL ile sorgulandığı sistem."
        case .storage: "Verinin en sonunda bit olarak durduğu yer: önce bellek tamponları, en sonunda SSD'deki flash hücreleri."
        }
    }

    /// Hafıza sarayı hikâyesi: her kat için akılda kalacak bir sahne.
    var palaceStory: String {
        switch self {
        case .ui: "Gökdelenin çatısında parlak mor bir kapı zili var. Parmağınla bastığın an bütün bina titreşerek uyanıyor."
        case .app: "Bir alt katta masada oturuyorsun. Eline kalemi alıp mektubu yazıyor, zarfın üstüne alıcının adresini (URL) ve imzanı (token) koyuyorsun."
        case .framework: "Mektubu postane gişesine uzatıyorsun. Memur önce 'cevabı zaten bizde mi?' diye rafına bakıyor, sonra kalın rehberden adresin numarasını (IP) buluyor, zarfı kırmızı mumla mühürlüyor (TLS)."
        case .kernel: "Gişenin arkasındaki depoda zarflar numaralanıp taşıma bandına diziliyor. Kayıp olan olursa yenisi yollanıyor — burası TCP'nin titiz deposu."
        case .physical: "Binanın tepesindeki dev anten mektubu sese çevirip havaya yayınlıyor. Kâğıt artık yok; sadece dalga var."
        case .internet: "Dalga en yakın modeme ulaşıyor ve otoyola çıkıyor. Her kavşakta bir tabela yalnızca bir sonraki şehri gösteriyor."
        case .edge: "Sunucu binasının girişinde gümrük var. Kimliğin kontrol ediliyor, mühür açılıyor ve resepsiyonist seni boş bir memura yönlendiriyor."
        case .serverOS: "Binanın posta odasında zarflar açılıyor ve doğru odanın kutusuna bırakılıyor. Uyuyan memur 'zil' sesiyle uyanıyor."
        case .backend: "Memur kimliğine bakıyor, dosyanı açıyor ve kurallara göre ne yapılacağına karar veriyor."
        case .cache: "Memurun masasında sarı yapışkan notlar var. Önce oraya bakıyor: not yoksa arşive inmek zorunda."
        case .database: "Kütüphaneye iniyorsun. Kütüphaneci bütün rafları gezmiyor; kataloğa (indeks) bakıp doğrudan doğru rafa gidiyor."
        case .storage: "En dipte, kırmızı ışıklı bodrum deposu. Kutular (8 KB'lık sayfalar) buradan alınıp merdivenlerden yukarı taşınıyor."
        }
    }

    var side: Side {
        switch self {
        case .ui, .app, .framework, .kernel, .physical: .client
        case .internet: .network
        case .edge, .serverOS, .backend, .cache, .database, .storage: .server
        }
    }

    var color: Color {
        let hue = 0.78 - Double(rawValue) * (0.78 / Double(Layer.allCases.count - 1))
        return Color(hue: hue, saturation: 0.72, brightness: 0.80)
    }
}

enum Side: CaseIterable, Identifiable {
    case client, network, server

    var id: Self { self }

    var emoji: String {
        switch self {
        case .client: "📱"
        case .network: "🌐"
        case .server: "🖥️"
        }
    }

    var title: String {
        switch self {
        case .client: "iPhone Binası"
        case .network: "Yol"
        case .server: "Sunucu Binası"
        }
    }
}
