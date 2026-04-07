#!/data/data/com.termux/files/usr/bin/bash

# ၁။ လိုအပ်သော Tool များ သွင်းခြင်း
echo "Installing dependencies..."
pkg update -y && pkg install proot tar curl wget -y

# ၂။ Clean Install ဖြစ်စေရန် ရှင်းလင်းခြင်း
FOLDER="ubuntu-fs"
[ -d "$FOLDER" ] && rm -rf "$FOLDER"
mkdir -p "$FOLDER"

# ၃။ Ubuntu 24.04.1 LTS (ARM64) ကို Download ဆွဲခြင်း
echo "Downloading Ubuntu 24.04.1 LTS..."
# မှတ်ချက်- ၂၄.၀၄.၃ link သည် error တက်တတ်သောကြောင့် ၂၄.၀၄.၁ ကို အသုံးပြုထားပါသည်
URL="https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.1-base-arm64.tar.gz"
wget -c $URL -O rootfs.tar.gz

# ၄။ File များကို ဖြည်ချခြင်း
echo "Extracting system files..."
if [ -f "rootfs.tar.gz" ]; then
    proot --link2symlink tar -xf rootfs.tar.gz -C "$FOLDER" --exclude='dev'
else
    echo "Error: Download failed!"
    exit 1
fi

# ၅။ DNS Fix (Internet ရအောင်)
echo "nameserver 8.8.8.8" > "$FOLDER/etc/resolv.conf"

# ၆။ Stable ဖြစ်သော GUI Setup (XFCE)
echo "Setting up XFCE Desktop (Stable Environment)..."
proot --link2symlink -0 -r $FOLDER /usr/bin/env -i HOME=/root TERM=$TERM PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin \
/bin/bash -c "
    apt update && apt upgrade -y
    DEBIAN_FRONTEND=noninteractive apt install -y xfce4 xfce4-goodies tightvncserver dbus-x11
    mkdir -p ~/.vnc
    echo '#!/bin/bash
    export USER=root
    export HOME=/root
    startxfce4 &' > ~/.vnc/xstartup
    chmod +x ~/.vnc/xstartup
"

# ၇။ Launch Script (start.sh)
cat <<EOT > start.sh
#!/data/data/com.termux/files/usr/bin/bash
proot --link2symlink -0 -r $FOLDER \
    -b /dev -b /proc -b /sys \
    -b /data/data/com.termux/files/home \
    -w /root \
    /usr/bin/env -i HOME=/root TERM=\$TERM PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login
EOT

chmod +x start.sh
rm rootfs.tar.gz
echo "-----------------------------------"
echo "Ubuntu 24.04.1 LTS Setup Complete!"
echo "Run: ./start.sh to begin."
echo "-----------------------------------"
