#!/bin/bash
# ==============================================
# Script de instalación LXQt + XRDP en Debian 12
# Optimizado para VPS con pocos recursos
# Autor: Enrique Rios
# ==============================================

# Variables configurables
USER="mabel"
PASSWORD="3b9ac9ff"

echo "=== Actualizando el sistema ==="
sudo apt update -y && sudo apt upgrade -y

echo "=== Instalando entorno gráfico mínimo (LXQt + Xorg + Openbox) ==="
sudo apt install -y lxqt-core xorg openbox lightdm xrdp htop

echo "=== Creando usuario $USER con privilegios administrativos ==="
if id "$USER" &>/dev/null; then
    echo "El usuario $USER ya existe, omitiendo creación."
else
    sudo adduser --disabled-password --gecos "" "$USER"
    echo "${USER}:${PASSWORD}" | sudo chpasswd
    sudo usermod -aG sudo "$USER"
    echo "Usuario $USER creado correctamente con permisos sudo."
fi

echo "=== Configurando XRDP ==="
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Configurar sesión LXQt por defecto
echo "lxqt-session" > /home/$USER/.xsession
sudo chmod +x /home/$USER/.xsession
sudo chown $USER:$USER /home/$USER/.xsession

# Copiar a /etc/skel para que futuros usuarios también tengan LXQt configurado
echo "lxqt-session" | sudo tee /etc/skel/.xsession > /dev/null

# Ajustar startwm.sh
echo "=== Configurando inicio de sesión LXQt directo con XRDP ==="
sudo cp /etc/xrdp/startwm.sh /etc/xrdp/startwm.sh.bak
sudo bash -c 'cat > /etc/xrdp/startwm.sh <<EOF
#!/bin/sh
# xrdp X session start script

if test -r /etc/profile; then
    . /etc/profile
fi

if test -r ~/.profile; then
    . ~/.profile
fi

# Iniciar LXQt directamente con XRDP, sin pasar por LightDM
export DESKTOP_SESSION=lxqt
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=LXQt

exec startlxqt
EOF'

sudo chmod +x /etc/xrdp/startwm.sh

echo "=== Deshabilitando LightDM (innecesario en VPS) ==="
sudo systemctl stop lightdm
sudo systemctl disable lightdm

echo "=== Eliminando componentes innecesarios para optimización de RAM ==="
sudo apt remove --purge -y \
    lxqt-powermanagement \
    qlipper \
    lxqt-notificationd \
    lxqt-runner \
    xscreensaver \
    xscreensaver-data \
    xscreensaver-data-extra \
    xscreensaver-gl \
    pulseaudio \
    pulseaudio-utils \
    gvfs \
    gvfs-daemons \
    gvfs-fuse \
    gvfs-backends \
    avahi-daemon \
    avahi-utils \
    system-config-printer \
    printer-driver-* \
    cups* \
    upower \
    #at-spi2-core \
    at-spi2-common

echo "=== Limpiando dependencias no utilizadas ==="
sudo apt autoremove -y
sudo apt clean

echo "=== Reiniciando servicios XRDP ==="
sudo systemctl restart xrdp

echo "=== Estableciendo zona horaria ==="
sudo timedatectl set-timezone America/Lima

echo
echo "=== Instalación completada correctamente ==="
echo "Puedes conectarte al escritorio LXQt mediante RDP (puerto 3389)."
echo "Usuario: $USER"
echo "Contraseña: $PASSWORD"
echo
echo "=== Reiniciando el sistema en 5 segundos para aplicar los cambios ==="
sleep 5
sudo reboot
