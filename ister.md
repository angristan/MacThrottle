# Gerekli Düzeltmeler

## Sorun
Branch'teki kod sadece macOS 26 (Tahoe) için derleniyor. `.glassEffect` API'si macOS 26'da tanıtılan yeni bir özellik ve eski sürümlerde mevcut değil.

## Build Hataları
```
AboutView.swift:11:22: error: value of type 'some View' has no member 'glassEffect'
```

## İstek
Proje hem **macOS 15 (Sequoia)** hem de **macOS 26 (Tahoe)** sürümlerini desteklemeli.

## Çözüm Yaklaşımı
Swift'te `#available` ve `@available` direktiflerini kullanarak koşullu kod yazılmalı:

```swift
// Örnek kullanım
if #available(macOS 26, *) {
    // macOS 26+ için glassEffect kullan
    content.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
} else {
    // macOS 15 için alternatif görünüm (örn: .background modifier)
    content.background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial))
}
```

## Kontrol Edilecek Dosyalar
- `MacThrottle/Views/AboutView.swift` - `.glassEffect` kullanımı var
- Diğer View dosyalarında da benzer macOS 26 API kullanımları kontrol edilmeli

## Kabul Kriterleri
- [ ] Proje macOS 15.2'de hatasız derlenmeli
- [ ] Proje macOS 26'da yeni UI özelliklerini kullanmalı
- [ ] `make dev` komutu başarıyla çalışmalı
