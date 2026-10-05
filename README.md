# İstek Yolculuğu (Request Journey) — iOS

Bir iOS uygulamasında butona dokunduğun andan, cevabın ekrana çizildiği ana kadar bir HTTP isteğinin
**arayüzden → işletim sistemine → ağa → sunucuya → veritabanına → diske** kadar indiği ve geri çıktığı
tüm süreci **görsel** olarak öğreten SwiftUI uygulaması.

Senaryo: `GET https://api.magaza.com/v1/orders` — "Siparişlerim" ekranında **Yenile**'ye dokunuluyor.

## Çalıştırma

1. Xcode 16 veya üstüyle `RequestJourney.xcodeproj` dosyasını aç.
2. Bir iPhone simülatörü seç (iOS 17+), **⌘R**.

> Xcode 15 kullanıyorsan: `brew install xcodegen && xcodegen` komutu `project.yml`'den projeyi yeniden üretir.

## Uygulamadaki 4 sekme

| Sekme | Ne öğretir |
|---|---|
| **Yolculuk** | 12 katlı renkli kule. ✉️ istek sol şeritten aşağı iner, 📦 yanıt sağ şeritten yukarı çıkar. 31 adımın her biri için: açıklama, animasyonlu diyagram (akış zinciri, el sıkışma okları, iç içe zarflar), o anda verinin gerçek görünümü (terminal kutusu) ve bir **hafıza çivisi**. Oynat / duraklat / kaydır / kata dokunarak atla. |
| **Hafıza Sarayı** | Her katman bir binanın katı ve bir sahne: 🔔 kapı zili → ✍️ mektup → 🏤 postane → 🚚 depo → 📻 telsiz → 🛣️ otoyol → 🛂 gümrük → 📬 posta odası → 🧑‍💼 memur → 🗒️ yapışkan not → 📚 kütüphane → 🗄️ bodrum. |
| **Zamanlama** | Şelale (waterfall) grafiği ve katman başına süre dağılımı. "Bağlantıyı yeniden kullan" anahtarıyla DNS + TCP + TLS'in nasıl kaybolduğunu gör. |
| **Test** | Kuleyi doğru sırayla yeniden inşa et; olayları doğru katmanla eşleştir. |

## 12 katman (mor çatıdan kırmızı bodruma 🌈)

| # | Katman | Benzetme | Teknoloji |
|---|---|---|---|
| 1 | Arayüz | 🔔 Kapı zili | SwiftUI, UIKit, dokunmatik |
| 2 | Uygulama Kodu | ✍️ Mektubu yazan sen | Swift, async/await |
| 3 | iOS Ağ Çatısı | 🏤 Postane gişesi | URLSession, DNS, TLS, HTTP/2 |
| 4 | iOS Çekirdeği | 🚚 Sıralama deposu | XNU, soket, TCP/IP |
| 5 | Donanım & Radyo | 📻 Telsiz | Wi-Fi, 5G |
| 6 | İnternet | 🛣️ Otoyollar | NAT, İSS, BGP, fiber |
| 7 | Kenar Katmanı | 🛂 Gümrük | CDN, WAF, yük dengeleyici |
| 8 | Sunucu Çekirdeği | 📬 Posta odası | Linux, NIC, epoll |
| 9 | Sunucu Uygulaması | 🧑‍💼 Memur | Router, middleware |
| 10 | Önbellek | 🗒️ Yapışkan not | Redis |
| 11 | Veritabanı | 📚 Kütüphane | PostgreSQL, indeks |
| 12 | Depolama | 🗄️ Bodrum deposu | Buffer, page cache, SSD |

## Kod yapısı

```
RequestJourney/
├── Models/        Layer (12 katman), JourneyStep, JourneyPlayer (oynatıcı)
├── Data/          JourneyData — 31 adımın tüm içeriği (öğretmek istediğini buradan düzenle)
└── Views/
    ├── Journey/   Kule, adım detayı, animasyonlu diyagramlar
    ├── Palace/    Hafıza sarayı
    ├── Timing/    Şelale grafiği
    ├── Quiz/      Testler
    └── Shared/    Ortak bileşenler
```
