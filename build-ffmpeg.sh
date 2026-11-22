#!/bin/bash
# Сборка FFmpeg (avutil/avcodec/avformat) через MSVC для Audacity.
# Запускать из окна mingw, открытого через нужный vcvars-ярлык (x64 / x86 / arm64).

set -e

SRC_DIR="/ffmpeg"

# Проверка, что MSVC-компилятор виден в этом окне
if ! command -v cl.exe >/dev/null 2>&1; then
    echo "Ошибка: cl.exe не найден. Откройте mingw через ярлык с vcvars."
    exit 1
fi

echo "Выберите архитектуру для сборки:"
echo "  1) x64   (по умолчанию)"
echo "  2) x86"
echo "  3) arm64"
read -p "Ваш выбор [1]: " choice

# Пустой ввод (просто Enter) = вариант 1
choice="${choice:-1}"

case "$choice" in
    1)
        ARCH="x86_64"
        TARGET_OS="win64"
        PREFIX="/mingw64/ffmpeg-build-msvc-x64"
        EXTRA_FLAGS=()
        ;;
    2)
        ARCH="x86"
        TARGET_OS="win32"
        PREFIX="/mingw32/ffmpeg-build-msvc-x86"
        EXTRA_FLAGS=(--disable-x86asm)
        ;;
    3)
        ARCH="aarch64"
        TARGET_OS="win64"
        PREFIX="/mingw64/ffmpeg-build-msvc-arm64"
        EXTRA_FLAGS=(--enable-cross-compile --disable-asm)
        ;;
    *)
        echo "Некорректный выбор: $choice"
        exit 1
        ;;
esac

echo ""
echo "=== Сборка FFmpeg для $ARCH (target-os=$TARGET_OS) ==="
echo "=== prefix: $PREFIX ==="
echo ""

cd "$SRC_DIR"

# make distclean пропускаем, если ffbuild/config.mak ещё не создан
if [ -f ffbuild/config.mak ]; then
    make distclean
fi

./configure \
    --toolchain=msvc \
    --arch="$ARCH" \
    --target-os="$TARGET_OS" \
    --prefix="$PREFIX" \
    --enable-shared \
    --disable-static \
    --disable-programs \
    --disable-doc \
    --disable-avdevice \
    --disable-avfilter \
    --disable-swscale \
    --disable-swresample \
    --disable-iconv \
    --disable-lzma \
    --disable-zlib \
    --disable-bzlib \
    "${EXTRA_FLAGS[@]}"

make -j"$(nproc)"
make install

echo ""
echo "=== Готово. Файлы установлены в: $PREFIX/bin ==="
ls "$PREFIX/bin"
