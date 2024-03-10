#!/bin/bash
echo "Davinci Resolve Install script v0.1"
echo ""
echo "Important: currently only Fedora 38/39 is supported! Support for other distributions may follow in the future."
echo ""
read -p "Continue installation? (y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

# Asking user for variables
echo "Please answer the following questions to proceed. If at any point you would like to cancel the installation, press Ctrl+C."

## ZIP Path
echo "Please enter the FULL PATH path to the zip archive you downloaded from the Blackmagic website (e.g. /home/username/Downloads/DaVinci_Resolve_Studio_18.6.5_Linux.zip):"
read -p "Installer path: " INSTALLERPATH

## GPU vendor
GPUVENDOR=0

PS3="Which is your GPU vendor?"
options=("NVIDIA" "AMD")
select opt in "${options[@]}"
do
    case $opt in
        "NVIDIA")
            GPUVENDOR=1
            ;;
        "AMD")
            GPUVENDOR=2
            ;;
    esac
done

echo "Information collected:"
echo "GPU Vendor (0=error, 1=Nvidia, 2=AMD): ${GPUVENDOR}"
echo "Path to installer zip-archive: ${INSTALLERPATH}"
read -p "Does this look correct? If not, cancel and reopen script. (y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

# Install dependencies
echo "Installing dependencies. You may be prompted for your sudo password."
#sudo dnf upgrade
sudo dnf install -y unzip libxcrypt-compat libcurl libcurl-devel mesa-libGLU alsa-plugins-pulseaudio libxcrypt-compat xcb-util-renderutil xcb-util-wm pulseaudio-libs xcb-util xcb-util-image xcb-util-keysyms libxkbcommon-x11 libXrandr libXtst mesa-libGLU mtdev libSM libXcursor libXi libXinerama libxkbcommon libglvnd-egl libglvnd-glx libglvnd-opengl libICE librsvg2 libSM libX11 libXcursor libXext libXfixes libXi libXinerama libxkbcommon libxkbcommon-x11 libXrandr libXrender libXtst libXxf86vm mesa-libGLU mtdev pulseaudio-libs xcb-util alsa-lib apr apr-util fontconfig freetype libglvnd fuse-libs

# Install GPU drivers
echo "Installing GPU drivers. You may be prompted for your sudo password."
if [ $# -eq 1 ]
then
    # For NVIDIA GPU
    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
    sudo dnf groupupdate sound-and-video
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
else
    # For AMD GPU
    sudo dnf install -y rocm-opencl
fi

# Make temporary directory
sudo mkdir /tmp/resolve-install

# Unzip and run installer
echo "Extracting installer archive..."
sudo unzip -d /tmp/resolve-install installerpath
echo "Setting installer permissions..."
sudo chmod +x /tmp/resolve-install/*.run
echo "Running the installer..."
sudo /tmp/resolve-install/*.run -i
echo "Davinci Resolve Installer has finished"

# Fix libraries

## libpanga
echo "Fixing libraries"

echo "Copying system glib-2 into Resolve libs"
sudo cp /lib64/libglib-2.0.* /opt/resolve/libs/

## libgdk_pixbuf-2.0.so.0
echo "Downloading GDK-Pixbuf library and extracting it to Resolve libs"
cd /tmp/resolve-install/
wget https://dl.fedoraproject.org/pub/fedora/linux/releases/38/Everything/x86_64/os/Packages/g/gdk-pixbuf2-2.42.10-2.fc38.x86_64.rpm
rpm2cpio ./gdk-pixbuf2-2.42.10-2.fc38.x86_64.rpm | cpio -idmv

cp -r ./usr/lib64/* /opt/resolve/libs/

# Render group
echo "Adding user to render group"
sudo usermod $USER -aG render

# done
echo "Installer script finished. Try opening Resolve from the application menu. If you only see a white screen, this is a known issue. Simply quit and re-open - it should now work normally."
