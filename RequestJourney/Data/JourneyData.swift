import Foundation

/// Senaryo: "Siparişlerim" ekranında "Yenile" butonuna dokunuluyor.
/// GET https://api.magaza.com/v1/orders → PostgreSQL'den kullanıcının siparişleri.
/// Süreler temsilidir (Wi-Fi, ~25 ms gidiş-dönüş varsayımı).
enum JourneyData {
    static let scenario = "GET https://api.magaza.com/v1/orders"

    static let steps: [JourneyStep] = rawSteps.enumerated().map { index, step in
        var step = step
        step.id = index
        return step
    }

    private static let rawSteps: [JourneyStep] = [

        // MARK: - İSTEK: aşağı doğru

        JourneyStep(
            layer: .ui, direction: .request,
            title: "Parmak camla buluşuyor",
            summary: "Ekrandaki kapasitif sensör dokunuşu algılar. Olay donanımdan çekirdeğe, oradan uygulamanın ana iş parçacığına (main thread) taşınır ve butonun eylemi tetiklenir.",
            details: [
                "Dokunmatik denetleyici parmağın konumunu saniyede 120 defaya kadar örnekler ve bir donanım kesmesi (interrupt) üretir.",
                "XNU çekirdeği (IOKit HID) olayı alır; `backboardd` sistem servisi dokunuşun hangi uygulamaya ait olduğunu belirler.",
                "Uygulamanın ana run loop'u olayı `UIEvent`/`UITouch` olarak alır; hit-testing ile dokunulan view bulunur.",
                "SwiftUI `Button` eylemi çalışır: `viewModel.loadOrders()`"
            ],
            memoryHook: "Çatıdaki kapı zilini çalıyorsun. Tek bir dokunuş bütün binayı uyandırır.",
            payload: """
            UITouch phase=.began  location=(196, 412)
            → hitTest → Button("Yenile")
            → action: viewModel.loadOrders()
            """,
            visual: .pipeline(["Sensör", "IOKit", "backboardd", "Run Loop", "Hit-test", "Button"]),
            durationMs: 8
        ),

        JourneyStep(
            layer: .app, direction: .request,
            title: "İstek nesnesi hazırlanır",
            summary: "Senin yazdığın kod devreye girer: ViewModel bir URLRequest oluşturur, kimlik jetonunu ekler ve async/await ile URLSession'a verir.",
            details: [
                "Ana iş parçacığı bloklanmaz: `await` noktasında görev askıya alınır, arayüz akmaya devam eder.",
                "Erişim jetonu (token) Keychain'den okunur ve `Authorization` başlığına eklenir.",
                "Ekran 'yükleniyor' durumuna geçer; bir ProgressView belirir."
            ],
            memoryHook: "Masada oturup mektubu yazıyorsun; zarfın üstüne alıcının adresini (URL) ve imzanı (token) koyuyorsun.",
            payload: """
            var req = URLRequest(url: URL(string: "https://api.magaza.com/v1/orders")!)
            req.setValue("Bearer eyJhbGci…", forHTTPHeaderField: "Authorization")
            isLoading = true
            let (data, response) = try await URLSession.shared.data(for: req)
            """,
            durationMs: 1
        ),

        JourneyStep(
            layer: .framework, direction: .request,
            title: "URLSession karar verir",
            summary: "URL Yükleme Sistemi (CFNetwork / Network.framework) isteği devralır: Cevap önbellekte var mı? Açık bir bağlantı kullanılabilir mi? Hangi protokol seçilecek?",
            details: [
                "`URLCache` kontrol edilir; geçerli bir kayıt varsa ağa hiç çıkılmaz.",
                "Cookie'ler ve varsayılan başlıklar (User-Agent, Accept-Encoding) eklenir.",
                "Aynı sunucuya açık (keep-alive) bir bağlantı varsa doğrudan kullanılır — DNS, TCP ve TLS adımları atlanır!",
                "App Transport Security (ATS) varsayılan olarak yalnızca HTTPS'e izin verir."
            ],
            memoryHook: "Postane gişesindeki memur önce rafa bakar: 'Bu mektubun cevabı zaten bizde mi?'",
            payload: """
            URLCache:  MISS
            Bağlantı havuzu: api.magaza.com:443 → açık bağlantı yok
            ALPN tercihi: h2, http/1.1
            """,
            visual: .pipeline(["URLCache?", "Cookie", "Bağlantı havuzu", "Protokol seçimi"]),
            durationMs: 1
        ),

        JourneyStep(
            layer: .framework, direction: .request,
            title: "DNS: İsimden IP adresine",
            summary: "Bilgisayarlar isimle değil numarayla konuşur. api.magaza.com adının IP adresi bulunmalıdır.",
            details: [
                "iOS'ta `mDNSResponder` servisi önce kendi önbelleğine bakar.",
                "Bulamazsa yapılandırılmış DNS çözümleyicisine (İSS, 1.1.1.1 vb.) UDP 53 ya da şifreli DoH/DoT ile sorar.",
                "Çözümleyici gerekirse sırayla kök (.) → .com → magaza.com'un yetkili sunucularına sorar.",
                "Cevap TTL süresi boyunca önbellekte tutulur; sonraki istekler bu adımı neredeyse bedavaya geçer."
            ],
            memoryHook: "Memur kalın telefon rehberini açıp 'Mağaza' isminin karşısındaki numarayı (IP) okur.",
            payload: """
            ;; QUESTION
            api.magaza.com.        IN  A
            ;; ANSWER
            api.magaza.com.  300   IN  A   203.0.113.10
            """,
            visual: .pipeline(["Yerel önbellek", "Çözümleyici", "Kök (.)", ".com", "magaza.com"]),
            durationMs: 25,
            skippedOnReuse: true
        ),

        JourneyStep(
            layer: .framework, direction: .request,
            title: "Güvenli bağlantı: TCP + TLS el sıkışmaları",
            summary: "Veri göndermeden önce iki el sıkışma gerekir: TCP güvenilir bir hat açar (1 gidiş-dönüş), TLS 1.3 bu hattı şifreler ve sunucunun kimliğini doğrular (1 gidiş-dönüş daha).",
            details: [
                "TCP: SYN → SYN-ACK → ACK. Bu kısmı aslında çekirdek yürütür; Network.framework sadece `connect()` der.",
                "TLS 1.3: ClientHello (SNI: api.magaza.com + anahtar paylaşımı) → ServerHello + sertifika + Finished.",
                "iOS, sertifika zincirini sistemdeki güvenilir kök sertifikalarla doğrular. Geçersizse istek burada biter.",
                "Sonuç: yalnızca iki tarafın bildiği simetrik oturum anahtarları."
            ],
            memoryHook: "Önce el sıkışırsınız 🤝, sonra yalnızca ikinizin bildiği bir şifrede anlaşıp zarfı mühürlersiniz 🔐.",
            payload: """
            TCP      203.0.113.10:443  ESTABLISHED   (1 RTT)
            TLS 1.3  TLS_AES_128_GCM_SHA256         (1 RTT)
            Sertifika: CN=api.magaza.com  ✓ güvenilir
            """,
            visual: .handshake([
                HandshakeMessage(fromClient: true, label: "SYN"),
                HandshakeMessage(fromClient: false, label: "SYN-ACK"),
                HandshakeMessage(fromClient: true, label: "ACK"),
                HandshakeMessage(fromClient: true, label: "ClientHello + key_share"),
                HandshakeMessage(fromClient: false, label: "ServerHello + Sertifika + Finished"),
                HandshakeMessage(fromClient: true, label: "Finished")
            ]),
            durationMs: 55,
            skippedOnReuse: true
        ),

        JourneyStep(
            layer: .framework, direction: .request,
            title: "HTTP/2 isteği çerçevelenir ve şifrelenir",
            summary: "İstek HTTP/2'nin ikili çerçevelerine (frame) dönüştürülür, başlıklar HPACK ile sıkıştırılır ve TLS kayıtlarının içine konup şifrelenir.",
            details: [
                "HTTP/2, tek bir bağlantı üzerinden birden çok isteği paralel 'stream'ler olarak taşır.",
                "GET isteğinde gövde yoktur; yalnızca bir HEADERS çerçevesi gider.",
                "Şifrelemeden sonra yoldaki herkes yalnızca anlamsız baytlar görür."
            ],
            memoryHook: "Mektup zarfa konur ve zarf kırmızı mumla mühürlenir.",
            payload: """
            HEADERS (stream 1)
              :method: GET
              :scheme: https
              :authority: api.magaza.com
              :path: /v1/orders
              authorization: Bearer eyJhbGci…
              accept: application/json
            """,
            durationMs: 0.2
        ),

        JourneyStep(
            layer: .kernel, direction: .request,
            title: "Sistem çağrısı: kullanıcı alanından çekirdeğe",
            summary: "Şifreli baytlar `send` sistem çağrısıyla çekirdeğe teslim edilir. Artık uygulamanın değil, işletim sisteminin sorumluluğundadır.",
            details: [
                "İşlemci kullanıcı modundan çekirdek moduna geçer (system call).",
                "Baytlar soketin gönderme tamponuna (send buffer) kopyalanır.",
                "TCP veriyi ~1400 baytlık segmentlere böler ve her birine sıra numarası (seq) verir.",
                "Kayıp paketleri yeniden göndermek ve tıkanıklığı kontrol etmek (congestion control) TCP'nin işidir."
            ],
            memoryHook: "Postanenin arka deposunda zarflar numaralanıp taşıma bandına dizilir.",
            payload: """
            send(fd=7, buf, 312) → 312
            TCP  52344 → 443  seq=1001 ack=5001  [PSH, ACK]
            """,
            durationMs: 0.05
        ),

        JourneyStep(
            layer: .kernel, direction: .request,
            title: "Kapsülleme: TCP → IP → Wi-Fi çerçevesi",
            summary: "Her katman kendi başlığını ekler: TCP portları, IP adresleri, Wi-Fi ise MAC adreslerini. Veri iç içe zarflara girer.",
            details: [
                "IP başlığı: kaynak 192.168.1.23 → hedef 203.0.113.10, TTL=64.",
                "Yönlendirme tablosu: hedef yerel ağda değil → paket varsayılan ağ geçidine (modem) gider.",
                "ARP ile modemin MAC adresi bulunur ve 802.11 çerçevesi oluşturulur."
            ],
            memoryHook: "🪆 Matruşka bebekleri: her katman bir öncekini kendi zarfının içine koyar.",
            payload: """
            802.11  a4:83:e7:… → 3c:22:fb:…
             IPv4   192.168.1.23 → 203.0.113.10  TTL=64
              TCP   52344 → 443
               TLS  Application Data (şifreli)
            """,
            visual: .nested(["Wi-Fi çerçevesi · MAC adresleri", "IP paketi · IP adresleri", "TCP segmenti · portlar", "TLS kaydı · şifreli", "✉️ HTTP/2 isteği"]),
            durationMs: 0.05
        ),

        JourneyStep(
            layer: .physical, direction: .request,
            title: "Bitler radyo dalgasına dönüşür",
            summary: "Wi-Fi yongası çerçeveyi bitlere, bitleri de 5 GHz radyo dalgalarına çevirir. Hücresel ağda aynı işi 5G modemi yapar.",
            details: [
                "Sürücü, çerçeveyi DMA ile ağ yongasının belleğine aktarır.",
                "Modülasyon (OFDM, QAM) ile bitler dalganın genliğine ve fazına kodlanır.",
                "Ortam boş mu diye dinlenir (CSMA/CA), sonra yayın yapılır; modem aldığını onaylar."
            ],
            memoryHook: "Telsiz: mektup artık kâğıt değil, havada uçan bir ses.",
            payload: """
            Kanal 36 (5 GHz) · 80 MHz · 1024-QAM
            RSSI −52 dBm · PHY hızı 1201 Mbps
            """,
            durationMs: 2
        ),

        JourneyStep(
            layer: .internet, direction: .request,
            title: "Modem ve İnternet Servis Sağlayıcısı",
            summary: "Modem NAT ile özel IP adresini genel IP adresine çevirir ve paketi fiber hattından İSS'ye yollar.",
            details: [
                "NAT: 192.168.1.23:52344 → 85.105.12.34:61001 eşlemesi bir tabloya yazılır. Cevap gelince bu tabloya bakılacak.",
                "Paket İSS'nin erişim ağından bölgesel yönlendiricilere çıkar.",
                "Fiberde ışık darbeleriyle ilerler (ışığın camdaki hızı ≈ 200.000 km/s)."
            ],
            memoryHook: "Sokağından ana caddeye çıkıyorsun; mahalle çıkışında arabanın plakası (IP) değişiyor.",
            payload: "NAT  192.168.1.23:52344  ⇄  85.105.12.34:61001",
            durationMs: 5
        ),

        JourneyStep(
            layer: .internet, direction: .request,
            title: "Yönlendirici atlamaları (hop)",
            summary: "Paket, her biri yalnızca 'bir sonraki durak' kararını veren onlarca yönlendiriciden geçer. Ağlar arasındaki yolları BGP belirler.",
            details: [
                "Her yönlendirici hedef IP'ye bakar ve yönlendirme tablosundan en uygun çıkışı seçer.",
                "Her atlamada TTL bir azalır; sıfır olursa paket atılır (sonsuz döngü koruması).",
                "Ağlar (AS'ler) birbirine BGP ile 'şu adreslere benden ulaşılır' diye duyuru yapar.",
                "Mesafe gecikmeyi belirler: İstanbul–Frankfurt ≈ 25 ms gidiş-dönüş."
            ],
            memoryHook: "Otoyol kavşakları: her tabela yalnızca bir sonraki şehri gösterir, kimse bütün haritayı bilmez.",
            payload: """
            $ traceroute api.magaza.com
             1  192.168.1.1        1.2 ms
             2  10.40.0.1          4.8 ms
             3  ae1.ist.isp.net    6.1 ms
             4  de-cix.fra        21.4 ms
             5  203.0.113.10      23.0 ms
            """,
            visual: .pipeline(["Modem", "İSS", "Değişim noktası (IX)", "Omurga", "Bulut ağı"]),
            durationMs: 12
        ),

        JourneyStep(
            layer: .edge, direction: .request,
            title: "CDN, güvenlik duvarı ve TLS sonlandırma",
            summary: "Sunucuya varmadan önce kenar katmanı karşılar: DDoS koruması, WAF kuralları ve TLS şifresinin çözülmesi burada olur.",
            details: [
                "Anycast sayesinde kullanıcıya en yakın kenar sunucusu (PoP) cevap verir.",
                "TLS burada sonlanır (termination); içeride ayrı bir bağlantı kullanılır.",
                "Önbelleklenebilir içerik (resim, statik dosya) burada cevaplanır; /v1/orders kişiye özel olduğu için geçer."
            ],
            memoryHook: "Gümrük kapısı: kimlik kontrol edilir, mühür açılır, şüpheliler geri çevrilir.",
            payload: """
            WAF: kurallar ✓     Hız sınırı: 12/100 dk
            Cache-Control: private  →  CDN BYPASS
            """,
            durationMs: 1
        ),

        JourneyStep(
            layer: .edge, direction: .request,
            title: "Yük dengeleyici sunucu seçer",
            summary: "Yük dengeleyici (load balancer), sağlıklı sunucular arasından birini seçer ve isteği ona iletir.",
            details: [
                "Algoritmalar: sırayla (round-robin), en az bağlantı, tutarlı hash…",
                "Sağlık kontrolleri (health check) cevap vermeyen sunucuları havuzdan çıkarır.",
                "`X-Forwarded-For` ve izleme için `X-Request-ID` başlıkları eklenir."
            ],
            memoryHook: "Resepsiyonist seni o an boş olan memurun masasına yönlendirir.",
            payload: """
            upstream api_pool {
              api-1  ✓
              api-2  ✓   ← seçildi (10.0.3.17)
              api-3  ✗   sağlık kontrolü başarısız
            }
            X-Request-ID: 7f3a-91c2
            """,
            durationMs: 0.5
        ),

        JourneyStep(
            layer: .serverOS, direction: .request,
            title: "Linux çekirdeği paketi karşılar",
            summary: "Sunucunun ağ kartı (NIC) paketi alır, Linux çekirdeği zarfları tersine açar ve veriyi bekleyen sürecin soketine koyar.",
            details: [
                "NIC paketi DMA ile belleğe yazar ve kesme üretir; yoğun trafikte NAPI ile toplu işlenir.",
                "Kapsülleme tersine açılır: Ethernet → IP → TCP → soketin alma kuyruğu.",
                "Web sunucusu `epoll` ile uyuyordu; 'okunacak veri var' olayıyla uyanır."
            ],
            memoryHook: "Binanın posta odası: zarflar açılır, doğru odanın kutusuna bırakılır, uyuyan memur zil sesiyle uyanır.",
            payload: """
            eth0 RX → ip_rcv() → tcp_v4_rcv() → sk_receive_queue
            epoll_wait() → EPOLLIN  fd=42
            """,
            visual: .pipeline(["NIC", "Kesme", "Ethernet", "IP", "TCP", "Soket", "epoll"]),
            durationMs: 0.05
        ),

        JourneyStep(
            layer: .backend, direction: .request,
            title: "Web sunucusu ve ara katmanlar",
            summary: "Uygulama sunucusu HTTP isteğini ayrıştırır, yönlendirici (router) ile doğru fonksiyonu bulur ve isteği ara katmanlardan (middleware) geçirir.",
            details: [
                "Router: `GET /v1/orders` → `OrdersController.list`",
                "Kimlik doğrulama: JWT imzası doğrulanır → userId = 42.",
                "Yetkilendirme, hız sınırı, loglama ve izleme (tracing) ara katmanları sırayla çalışır."
            ],
            memoryHook: "Memur kimliğine bakar, dosyanı açar ve doğru birime havale eder.",
            payload: """
            [req 7f3a] GET /v1/orders  user=42
            middleware: auth ✓  rateLimit ✓  trace ✓
            → OrdersController.list()
            """,
            visual: .pipeline(["HTTP ayrıştır", "Router", "Auth (JWT)", "Hız sınırı", "Log/Trace", "Controller"]),
            durationMs: 2
        ),

        JourneyStep(
            layer: .backend, direction: .request,
            title: "İş mantığı ve sorgu hazırlığı",
            summary: "Controller servis katmanını çağırır. Servis önce önbelleğe bakmaya, yoksa veritabanından okumaya karar verir; ORM SQL sorgusunu üretir.",
            details: [
                "Servis katmanı iş kurallarını uygular: kullanıcı yalnızca kendi siparişlerini görebilir.",
                "ORM kod nesnelerini SQL'e çevirir; parametreler SQL enjeksiyonuna karşı ayrı gönderilir.",
                "Bu desene 'cache-aside' denir: önce önbellek, sonra kaynak."
            ],
            memoryHook: "Memur önce masadaki yapışkan nota, sonra arşive bakmaya karar verir.",
            payload: """
            orders = cache.get("orders:user:42")
                  ?? db.query("SELECT … WHERE user_id = $1", [42])
            """,
            durationMs: 0.5
        ),

        JourneyStep(
            layer: .cache, direction: .request,
            title: "Redis önbelleği: ıska (miss)",
            summary: "RAM'de çalışan Redis'e sorulur. Bu sefer kayıt yok (cache miss), yani veritabanına inmek gerekiyor.",
            details: [
                "Redis veriyi bellekte tutar; cevap süresi milisaniyenin altındadır.",
                "Cache HIT olsaydı yolculuk burada geri döner, veritabanına hiç inilmezdi.",
                "Anahtar tasarımı önemlidir: `orders:user:42`"
            ],
            memoryHook: "Masadaki sarı yapışkan nota bakıyorsun… boş. Arşive inmek zorundasın.",
            payload: """
            redis> GET orders:user:42
            (nil)      ← MISS
            """,
            durationMs: 0.5
        ),

        JourneyStep(
            layer: .database, direction: .request,
            title: "Bağlantı havuzu ve SQL protokolü",
            summary: "Uygulama, hazırda bekleyen bir veritabanı bağlantısını havuzdan ödünç alır ve sorguyu PostgreSQL'in kablo protokolüyle gönderir.",
            details: [
                "Her istekte yeni bağlantı açmak pahalıdır (TCP + kimlik doğrulama); havuz bunu önler.",
                "Sorgu Parse / Bind / Execute mesajlarıyla gider; parametrenin ($1) değeri ayrıca taşınır.",
                "PostgreSQL her bağlantı için ayrı bir süreç (backend process) çalıştırır."
            ],
            memoryHook: "Kütüphanenin kapısındaki görevliye talep fişini uzatıyorsun.",
            payload: """
            pool: 8/20 kullanımda → bağlantı #3
            Parse: SELECT id, total, status FROM orders
                   WHERE user_id = $1
                   ORDER BY created_at DESC LIMIT 20
            Bind:  $1 = 42
            """,
            durationMs: 0.3
        ),

        JourneyStep(
            layer: .database, direction: .request,
            title: "Sorgu planlanır ve çalıştırılır",
            summary: "PostgreSQL sorguyu ayrıştırır, en ucuz çalıştırma planını seçer ve B-tree indeksi üzerinden yalnızca ilgili satırları bulur.",
            details: [
                "Parser: SQL metni → sözdizimi ağacı.",
                "Planner / Optimizer: istatistiklere bakarak 'tablonun tamamını mı tarayayım, indeksi mi kullanayım?' kararını verir.",
                "Executor: `idx_orders_user_created` indeksiyle doğrudan ilgili sayfalara gider.",
                "MVCC: her satırın bu işlem (transaction) için görünür olup olmadığı kontrol edilir."
            ],
            memoryHook: "Kütüphaneci bütün rafları gezmez; kataloğa (indeks) bakıp doğrudan doğru rafa gider.",
            payload: """
            EXPLAIN
            Limit  (cost=0.43..12.80 rows=20)
              ->  Index Scan using idx_orders_user_created on orders
                    Index Cond: (user_id = 42)
            """,
            visual: .pipeline(["Parser", "Rewriter", "Planner", "Executor", "Buffer pool"]),
            durationMs: 1.5
        ),

        JourneyStep(
            layer: .storage, direction: .request,
            title: "Bellekten diske: sayfalar okunur",
            summary: "Gereken 8 KB'lık veri sayfaları önce PostgreSQL'in bellek tamponunda, sonra işletim sisteminin sayfa önbelleğinde aranır; ikisinde de yoksa SSD'den okunur.",
            details: [
                "shared_buffers isabeti: veri zaten RAM'de, nanosaniyeler.",
                "OS sayfa önbelleği: `pread` sistem çağrısı yine RAM'den döner.",
                "NVMe SSD okuması ≈ 0,1 ms. (Eski dönen diskte ≈ 10 ms olurdu — 100 kat yavaş!)",
                "Yazma işlemlerinde önce WAL (write-ahead log) diske `fsync` edilir: dayanıklılığın sırrı."
            ],
            memoryHook: "Bodrumdaki kırmızı ışıklı depo. En dibe ulaştın; buradan sonrası yukarı tırmanış.",
            payload: """
            Buffers: shared hit=3 read=1
            I/O Timings: read=0.094 ms
            pread64(fd=18, buf, 8192, offset=0x2A4000)
            """,
            visual: .pipeline(["shared_buffers", "OS sayfa önbelleği", "NVMe SSD", "NAND flash"]),
            durationMs: 0.1
        ),

        // MARK: - YANIT: yukarı doğru

        JourneyStep(
            layer: .database, direction: .response,
            title: "Satırlar toplanır ve geri gönderilir",
            summary: "Executor bulduğu satırları DataRow mesajları olarak bağlantı üzerinden uygulamaya akıtır; bağlantı havuza geri döner.",
            details: [
                "20 satır, her biri bir DataRow mesajı.",
                "Sonunda `CommandComplete: SELECT 20` gelir.",
                "Bağlantı serbest bırakılır, bir sonraki isteğe hazırdır."
            ],
            memoryHook: "Kütüphaneci istediğin dosyaları kucaklayıp merdivenleri çıkmaya başlar.",
            payload: """
              id   | total  | status
            -------+--------+---------
             9812  | 249.90 | kargoda
             9790  |  89.50 | teslim
             …
            (20 rows)
            """,
            durationMs: 0.2
        ),

        JourneyStep(
            layer: .cache, direction: .response,
            title: "Sonuç önbelleğe yazılır",
            summary: "Bir dahaki sefere veritabanına inmemek için sonuç Redis'e süreli (TTL) olarak yazılır.",
            details: [
                "`SET … EX 60`: kayıt 60 saniye geçerli.",
                "Yeni sipariş gelince bu anahtar silinir (cache invalidation).",
                "'Bilgisayar biliminde iki zor şey vardır: önbellek geçersiz kılma ve isim vermek.'"
            ],
            memoryHook: "Yapışkan notu güncelliyorsun: bir dahaki sefere arşive inmene gerek kalmayacak.",
            payload: """
            redis> SET orders:user:42 '[{"id":9812,…}]' EX 60
            OK
            """,
            durationMs: 0.3
        ),

        JourneyStep(
            layer: .backend, direction: .response,
            title: "JSON yanıtı oluşturulur",
            summary: "Satırlar kod nesnelerine, nesneler de JSON'a dönüştürülür. Durum kodu ve başlıklar eklenir, gövde sıkıştırılır.",
            details: [
                "Serileştirme: model → JSON.",
                "`200 OK` + `Content-Type` + `Cache-Control` başlıkları.",
                "Brotli/gzip ile ~4 KB → ~1 KB.",
                "İstek logu ve süre metriği yazılır (p95 gecikme izlenir)."
            ],
            memoryHook: "Memur cevap mektubunu yazar ve yeni bir zarfa koyar.",
            payload: """
            HTTP/2 200
            content-type: application/json
            content-encoding: br
            cache-control: private, max-age=0

            {"orders":[{"id":9812,"total":249.90,"status":"kargoda"}, …]}
            """,
            durationMs: 1
        ),

        JourneyStep(
            layer: .serverOS, direction: .response,
            title: "Sunucu çekirdeği yanıtı yollar",
            summary: "Yanıt baytları soket üzerinden Linux çekirdeğine verilir; TCP segmentlere bölünür, IP ve Ethernet başlıkları eklenir ve NIC'ten çıkar.",
            details: [
                "Tıkanıklık penceresi (cwnd), onay beklemeden bir seferde ne kadar veri yollanabileceğini belirler.",
                "Büyük yanıtlar onlarca segmente bölünür; istemci her birini onaylar (ACK).",
                "Kapsülleme bu sefer sunucu tarafında, aynı mantıkla yapılır."
            ],
            memoryHook: "Posta odası cevap zarfını kargoya verir.",
            payload: """
            write(fd=42, buf, 1084) → 1084
            TCP  443 → 61001  seq=5001  [PSH, ACK]
            """,
            durationMs: 0.1
        ),

        JourneyStep(
            layer: .edge, direction: .response,
            title: "Kenar katmanından çıkış",
            summary: "Yük dengeleyici yanıtı alır ve istemciyle olan TLS bağlantısı üzerinden şifreleyerek geri yollar.",
            details: [
                "Yanıt süresi ve durum kodu metrik olarak kaydedilir.",
                "Güvenlik başlıkları (HSTS vb.) eklenebilir.",
                "Herkese açık içerik olsaydı CDN bir kopyasını saklardı."
            ],
            memoryHook: "Gümrükten çıkış: cevap yeniden mühürlenip yola çıkarılır.",
            payload: """
            upstream_response_time=4.9ms  status=200
            strict-transport-security: max-age=31536000
            """,
            durationMs: 0.5
        ),

        JourneyStep(
            layer: .internet, direction: .response,
            title: "İnternetten geri dönüş",
            summary: "Yanıt paketleri internetten geri geçer — her zaman aynı yoldan değil! Modem NAT tablosuna bakıp paketi doğru cihaza teslim eder.",
            details: [
                "Gidiş ve dönüş rotaları farklı olabilir (asimetrik yönlendirme).",
                "NAT: 85.105.12.34:61001 → 192.168.1.23:52344",
                "Işık hızı sınırı yüzünden bu yolculuk genelde toplam sürenin en büyük parçasıdır."
            ],
            memoryHook: "Dönüş yolculuğu: otoyoldan mahallene, mahalleden kapına.",
            payload: "NAT eşleşmesi bulundu: 85.105.12.34:61001 → 192.168.1.23:52344",
            durationMs: 15
        ),

        JourneyStep(
            layer: .physical, direction: .response,
            title: "Radyo dalgası yeniden bite dönüşür",
            summary: "iPhone'un Wi-Fi yongası dalgayı çözer (demodülasyon), çerçevenin hata kontrolünü (FCS) yapar ve kesmeyle çekirdeğe haber verir.",
            details: [
                "Bozuk çerçeve atılır ve Wi-Fi seviyesinde yeniden gönderilir.",
                "Pil tasarrufu: trafik yokken radyo uyur; ilk paket bu yüzden bazen gecikir."
            ],
            memoryHook: "Telsizden gelen sesi yeniden kâğıda yazıyorsun.",
            payload: "RX 802.11 çerçevesi · FCS ✓ · 1138 bayt",
            durationMs: 2
        ),

        JourneyStep(
            layer: .kernel, direction: .response,
            title: "iOS çekirdeği paketleri birleştirir",
            summary: "XNU çekirdeği zarfları tersine açar: Wi-Fi → IP → TCP. Segmentleri sıraya koyar, ACK gönderir ve veriyi soket tamponunda bekletir.",
            details: [
                "Sıra dışı gelen segmentler bekletilir, eksikler yeniden istenir.",
                "Veri hazır olunca Network.framework'ün bekleyen okuması uyandırılır."
            ],
            memoryHook: "Depoda gelen kolilerin numaraları kontrol edilip sıraya dizilir.",
            payload: """
            tcp_input: seq=5001 len=1084 → sırada ✓
            ACK 6085 gönderildi
            soket alma tamponu: 1084 bayt
            """,
            visual: .pipeline(["802.11", "IP", "TCP", "Soket tamponu"]),
            durationMs: 0.1
        ),

        JourneyStep(
            layer: .framework, direction: .response,
            title: "Şifre çözülür, URLSession devam eder",
            summary: "Network.framework TLS kayıtlarının şifresini çözer, HTTP/2 çerçevelerini birleştirir, sıkıştırmayı açar ve askıdaki `await`'i sonuçla devam ettirir.",
            details: [
                "Yanıt kurallara uyuyorsa URLCache'e yazılır.",
                "Bağlantı açık tutulur (keep-alive): sonraki istek DNS, TCP ve TLS'i atlar.",
                "async fonksiyonun devamı (continuation) çalışmak üzere planlanır."
            ],
            memoryHook: "Postane gişesindeki memur cevap mektubunun mührünü açıp sana uzatır.",
            payload: """
            (data: 4.1 KB, response: <NSHTTPURLResponse 200>)
            metrics: dns=24ms connect=27ms tls=28ms ttfb=41ms
            """,
            visual: .pipeline(["TLS çöz", "HTTP/2 birleştir", "Brotli aç", "URLResponse", "await devam"]),
            durationMs: 0.3
        ),

        JourneyStep(
            layer: .app, direction: .response,
            title: "JSON çözülür, durum güncellenir",
            summary: "Kod kaldığı yerden devam eder: JSONDecoder baytları Swift modellerine çevirir ve ana iş parçacığında (@MainActor) durum güncellenir.",
            details: [
                "Hatalar (401, ağ kopması, bozuk JSON) burada yakalanır.",
                "Arayüzü etkileyen her değişiklik ana iş parçacığında yapılmalıdır.",
                "`isLoading = false`, `orders = sonuç`"
            ],
            memoryHook: "Gelen mektubu okuyup önemli kısımlarını defterine (state) geçiriyorsun.",
            payload: """
            struct Order: Decodable { let id: Int; let total: Double; let status: String }

            self.orders = try JSONDecoder().decode([Order].self, from: data)
            self.isLoading = false        // @MainActor
            """,
            durationMs: 1
        ),

        JourneyStep(
            layer: .ui, direction: .response,
            title: "Ekran yeniden çizilir",
            summary: "SwiftUI değişen durumu fark eder, body'yi yeniden hesaplar ve farkları bulur. Core Animation katmanları render sunucusuna yollar, GPU pikselleri boyar ve liste bir sonraki ekran yenilemesinde görünür.",
            details: [
                "Diffing: yalnızca değişen view'lar güncellenir.",
                "Layout → çizim → Core Animation 'commit'.",
                "Render sunucusu ve GPU kareyi oluşturur.",
                "120 Hz ekranda her kareye ~8 ms düşer; kaçırılırsa 'takılma' (hitch) olur."
            ],
            memoryHook: "Kapı açılır ve cevap gözlerinin önünde. Yolculuk çatıda başladı, çatıda bitti.",
            payload: """
            List(orders) → 20 satır
            CA::Transaction::commit()
            kare 1184 · vsync +8.3 ms ✓
            """,
            visual: .pipeline(["State değişti", "body", "Diff", "Layout", "CA commit", "Render sunucusu", "GPU", "Ekran"]),
            durationMs: 16
        )
    ]
}
