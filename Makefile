.PHONY: setup generate build-android run-android install-release clean

# 1. İlk kurulum
setup:
	flutter pub get
	cargo install flutter_rust_bridge_codegen --version 2.11.1
	cargo install cargo-ndk

# 2. Köprü Kodlarını Üret (Config dosyasını otomatik okur)
generate:
	flutter_rust_bridge_codegen generate

# 3. Android için Rust Kütüphanesini Derle (Otomatik Lib Copy ile)
build-android:
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

# [YENİ] Temizlik Hedefi
clean:
	@echo "🧹 Cleaning project artifacts..."
	flutter clean
	rm -rf rust/target
	rm -rf android/app/src/main/jniLibs/*

# 4. Cihaza OTOMATİK YÜKLE VE ÇALIŞTIR (Debug Modu - Hot Reload destekler)
# [GÜNCELLENDİ]: Artık her çalıştırmadan önce temizlik ve build yapar.
run-android: clean generate build-android
	flutter run --debug

# 5. Cihaza FİNAL SÜRÜMÜ YÜKLE (Performance Mode)
deploy-device: clean generate build-android
	flutter run --release