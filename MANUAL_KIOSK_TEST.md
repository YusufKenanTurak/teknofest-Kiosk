# Manuel kiosk test listesi (yatay 1920×1080)

Cihaz: Teknofest standı Android kiosk (30 Eylül – 4 Ekim)

## Açılış

- [ ] Uygulama açılıyor
- [ ] Ekran yatay (landscape) kilitli
- [ ] Açılış başlığı doğru: `HANGİ MÜHENDİSLİK DALINA YATKINSIN?`
- [ ] Açılış gövde metni doğru
- [ ] Türkçe karakterler (İ, ş, ğ, ü, ö, ç, â) bozulmuyor
- [ ] `TESTE BAŞLA` çalışıyor
- [ ] Status bar / navigation bar görünmüyor veya kaydırınca geçici olup geri gizleniyor
- [ ] Ekran zaman aşımıyla kapanmıyor

## Test akışı

- [ ] Soru 1 doğru
- [ ] Tüm 15 soru doğru sırada
- [ ] Tüm 60 şık metni doğru
- [ ] Şıklar büyük, 2×2 ızgara, kolay dokunuluyor
- [ ] Şık seçimleri çalışıyor
- [ ] Seçimde kısa vurgu / “Sonraki soruya geçiliyor...” görünüyor
- [ ] İlerleme (SORU n / 15 ve yüzde) düzgün
- [ ] 15. sorudan sonra `ROTAN BELİRLENİYOR...` geçiş ekranı geliyor
- [ ] Ardından sonuç geliyor
- [ ] Sonuçta başarılı/başarısız ifadesi yok
- [ ] UI’da geri / hamburger / ayarlar yok

## Sonuç ekranları

Her alanı en az bir kez üretecek şekilde kontrol:

- [ ] 💻 Bilgisayar Mühendisliği
- [ ] 🧪 Kimya Mühendisliği
- [ ] 🌱 Çevre Mühendisliği
- [ ] ⚙️ Makine Mühendisliği
- [ ] ⚡ Elektrik-Elektronik Mühendisliği
- [ ] 📊 Endüstri Mühendisliği
- [ ] İnşaat Mühendisliği (onaylı emoji karakteri dahil)
- [ ] Açıklama ve slogan metinleri birebir doğru

## Restart

- [ ] `Testi Tekrar Başlat` çalışıyor
- [ ] `BİTİR` de açılış ekranına dönüyor ve state temizliyor
- [ ] Restart sonrası puan/seçim/sonuç taşınmıyor
- [ ] 50+ ardışık restart sonrası uygulama yavaşlamıyor / crash olmuyor

## Kiosk / cihaz

- [ ] Geri tuşu / geri jesti test sırasında önceki soruya dönmüyor
- [ ] Hızlı art arda tıklama crash oluşturmuyor ve soru atlamıyor
- [ ] 30 sn dokunulmazsa zaman aşımı ekranı çıkıyor, ardından açılış
- [ ] Internet kapalıyken START → 15 soru → sonuç → restart çalışıyor
- [ ] Uygulama uzun süre açık kalabiliyor
- [ ] 1920×1080 ve yakın landscape çözünürlüklerde düzen bozulmuyor
- [ ] Uzun şık metinleri taşmıyor
- [ ] Home tuşu davranışı kabul edilebilir (launcher/pin ayarı yapılmış)
- [ ] Uygulama process öldükten sonra yeniden açılınca temiz açılış ekranı geliyor
- [ ] Rotation denemesi landscape dışında kalıcı portrait’e düşmüyor

## APK güncelleme

- [ ] `version.json` `https://testapp.limak.com.tr/teknofest/app/version.json` adresinden 200 JSON dönüyor
- [ ] Sürüm eşitken güncelleme diyaloğu çıkmıyor
- [ ] Sunucu sürümü daha yüksekken “Yeni Sürüm Mevcut” çıkıyor
- [ ] Güncelle ile APK inip kurulum ekranı açılıyor
- [ ] İnternet yokken uygulama yine açılıyor
- [ ] Kurulum iptal edilince kiosk akışı bozulmuyor
- [ ] Aynı sürüm tekrar tekrar indirilmiyor (cihazda geçerli APK varsa reuse)

## Production kurulum

- [ ] Release APK kuruldu (`app-release.apk`)
- [ ] Play Store otomatik güncelleme kioskta açık değil
- [ ] Cihaz saati ve dil Türkçe
- [ ] Bildirimler ve jest navigasyonu mümkün olduğunca kapatıldı
- [ ] Cihaz şarjda ve kiosk standına kilitli
