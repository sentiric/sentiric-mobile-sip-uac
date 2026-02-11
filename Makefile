.PHONY: setup generate build-android run-android install-release

# 1. İlk kurulum
setup:
	flutter pub get
	cargo install flutter_rust_bridge_codegen --version 2.11.1
	cargo install cargo-ndk

# 2. Köprü Kodlarını Üret (Config dosyasını otomatik okur)
generate:
	flutter_rust_bridge_codegen generate
	
# 3. Android için Rust Kütüphanesini Derle (Hem ARM64 hem ARMv7)
build-android:
	cd rust && cargo ndk -t arm64-v8a -t armeabi-v7a build --release
	mkdir -p android/app/src/main/jniLibs/arm64-v8a
	mkdir -p android/app/src/main/jniLibs/armeabi-v7a
	cp rust/target/aarch64-linux-android/release/libmobile_uac.so android/app/src/main/jniLibs/arm64-v8a/
	cp rust/target/armv7-linux-androideabi/release/libmobile_uac.so android/app/src/main/jniLibs/armeabi-v7a/

# 4. Cihaza OTOMATİK YÜKLE VE ÇALIŞTIR (Debug Modu - Hot Reload destekler)
run-android: generate
	flutter run --debug

# 5. Cihaza FİNAL SÜRÜMÜ YÜKLE (Performance Mode)
# Cihaz bağlıyken bunu çalıştırırsan direkt telefona kurar ve açar.
deploy-device: generate build-android
	flutter run --release