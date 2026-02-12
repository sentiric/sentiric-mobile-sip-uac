.PHONY: setup generate build-android run-android deploy-device clean-android clean-all

# ==============================================================================
# SENTIRIC MOBILE UAC - ORCHESTRATION MAKEFILE (v2.0)
# ==============================================================================

# 1. İlk kurulum (SDK'lar ve araçlar için)
setup:
	@echo "--- : Gerekli araçlar kuruluyor... ---"
	flutter pub get
	cargo install flutter_rust_bridge_codegen --version 2.11.1
	cargo install cargo-ndk

# 2. Köprü Kodlarını Üret
generate:
	@echo "---: Rust/Dart köprü kodları üretiliyor... ---"
	flutter_rust_bridge_codegen generate
	
# 3. Android için Rust Kütüphanesini Derle (C++ bağımlılıkları dahil)
build-android:
	@echo "--- : Rust çekirdeği Android için derleniyor... ---"
	# ANDROID_HOME environment variable'ının sistemde tanımlı olduğunu varsayıyoruz.
	cd rust && cargo ndk -t arm64-v8a -t armeabi-v7a -o ../android/app/src/main/jniLibs build --release
	
	# libc++_shared.so dosyasını bul ve manuel olarak kopyala (Kritik Adım)
	@echo "🔍 C++ Shared Library aranıyor ve kopyalanıyor..."
	@mkdir -p android/app/src/main/jniLibs/arm64-v8a
	@find $$(echo $$ANDROID_HOME)/ndk -name "libc++_shared.so" | grep "aarch64" | head -n 1 | xargs -I {} cp {} android/app/src/main/jniLibs/arm64-v8a/
	@echo "✅ ARM64 libc++_shared.so kopyalandı."
	@mkdir -p android/app/src/main/jniLibs/armeabi-v7a
	@find $$(echo $$ANDROID_HOME)/ndk -name "libc++_shared.so" | grep "arm-linux-androideabi" | head -n 1 | xargs -I {} cp {} android/app/src/main/jniLibs/armeabi-v7a/
	@echo "✅ ARMv7 libc++_shared.so kopyalandı."

# 4. Temizlik Hedefleri (Ayrıştırıldı)
clean-android:
	@echo "--- : Flutter & Android artıkları temizleniyor... ---"
	flutter clean
	rm -rf android/app/src/main/jniLibs/*

clean-all: clean-android
	@echo "--- : Rust derleme önbelleği temizleniyor... ---"
	rm -rf rust/target

# 5. Cihaza OTOMATİK YÜKLE VE ÇALIŞTIR (Debug Modu)
# [GÜNCELLENDİ]: Artık her çalıştırmadan önce SADECE Android tarafını temizler.
run-android: clean-android generate build-android
	@echo "---: Uygulama cihaza yükleniyor (Debug)... ---"
	flutter run --debug

# 6. Cihaza FİNAL SÜRÜMÜ YÜKLE (Performance Mode)
deploy-device: clean-android generate build-android
	@echo "--- : Uygulama cihaza yükleniyor (Release)... ---"
	flutter run --release