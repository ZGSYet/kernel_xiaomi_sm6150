#!/bin/bash
#
# Compile script for kernel
#

# --- KONFIGURASI TELEGRAM ---
TG_TOKEN="8647652050:AAG0ZKtMuE4NhlOKx8EHz4VHfgPLlguMTqw"
TG_CHAT_ID="7540957411"
# ----------------------------

SECONDS=0 # builtin bash timer

ZIPNAME="NekoPoi-$(date '+%Y%m%d-%H%M').zip"

DEVICE="courbet"
export ARCH=arm64
export KBUILD_BUILD_USER=aryan
export KBUILD_BUILD_HOST=celeste
export PATH="/home/celeste/aryan/linux-x86/clang-r510928/bin/:$PATH"

if [[ $1 = "-c" || $1 = "--clean" ]]; then
	rm -rf out
	echo "Cleaned output folder"
fi

echo -e "\nStarting compilation for $DEVICE...\n"
make O=out ARCH=arm64 ${DEVICE}_defconfig
make -j$(nproc) \
    O=out \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi-

kernel="out/arch/arm64/boot/Image.gz"
dtbo="out/arch/arm64/boot/dtbo.img"
dtb="out/arch/arm64/boot/dtb.img"

if [ ! -f "$kernel" ] || [ ! -f "$dtbo" ] || [ ! -f "$dtb" ]; then
	echo -e "\nCompilation failed!"
	exit 1
fi

echo -e "\nKernel compiled successfully! Zipping up...\n"

if [ -d "$AK3_DIR" ]; then
	cp -r $AK3_DIR AnyKernel3
else
	if ! git clone -q https://github.com/ZGSYet/AnyKernel3 -b master AnyKernel3; then
		echo -e "\nAnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
		exit 1
	fi
fi

# Modify anykernel.sh to replace device names
sed -i "s/device\.name1=.*/device.name1=${DEVICE}/" AnyKernel3/anykernel.sh
sed -i "s/device\.name2=.*/device.name2=${DEVICE}in/" AnyKernel3/anykernel.sh

cp $kernel AnyKernel3
cp $dtbo AnyKernel3
cp $dtb AnyKernel3
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x .git
cd ..
rm -rf AnyKernel3
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"

if test -z "$(git rev-parse --show-cdup 2>/dev/null)" &&
   head=$(git rev-parse --verify HEAD 2>/dev/null); then
	HASH="$(echo $head | cut -c1-8)"
fi

# 5. Step: Final
DURATION="$((SECONDS / 60)) menit $((SECONDS % 60)) detik"
tg_update "🛠 **Kernel Build Update**
✅ **Status**: Rampung dlm $DURATION! Lagi upload..."

curl -F document=@"$ZIPNAME" \
     -F chat_id="$TG_CHAT_ID" \
     -F caption="✅ **NekoPoi Selesai!**
📦 **File**: \`$ZIPNAME\`
⏱ **Durasi**: $DURATION
👤 **User**: $KBUILD_BUILD_USER" \
     -F parse_mode="Markdown" \
     "https://api.telegram.org/bot$TG_TOKEN/sendDocument"
