# AlmaLinux 8 kickstart file for base WSL image

# install
url --url https://repo.almalinux.org/almalinux/8/BaseOS/$basearch/os/

lang en_US.UTF-8
keyboard us
timezone --nontp --utc UTC

network --activate --bootproto=dhcp --device=link --onboot=on
firewall --disabled
selinux --disabled

bootloader --disable
zerombr
clearpart --all --initlabel
autopart --fstype=ext4 --type=plain --nohome --noboot --noswap

rootpw --lock

shutdown

%packages --ignoremissing --excludedocs --instLangs=en --nocore
@^minimal-environment
dmidecode
findutils
file
gdb-gdbserver
iputils
libmetalink
nano
passwd
pciutils
procps-ng
rootfiles
sudo
tar
tmux
usermode
vim-minimal
virt-what
which
yum
yum-utils
xz
-audit
-dnf-plugin-subscription-manager
-dosfstools
-e2fsprogs
-firewalld
-fuse-libs
-gnupg2-smime
-grub\*
-iptables
-kernel
-libss
-openssh-server
-open-vm-tools
-os-prober
-pinentry
-qemu-guest-agent
-shared-mime-info
-subscription-manager
-trousers
-xfsprogs
-xkeyboard-config
%end

%post --erroronfail --log=/root/anaconda-post.log
# generate build time file for compatibility with CentOS
/bin/date +%Y%m%d_%H%M > /etc/BUILDTIME

# set DNF infra variable to container for compatibility with CentOS
echo 'container' > /etc/dnf/vars/infra

# import AlmaLinux PGP key
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

# install only en_US.UTF-8 locale files, see
# https://fedoraproject.org/wiki/Changes/Glibc_locale_subpackaging for details
LANG="en_US"
echo '%_install_langs en_US.UTF-8' > /etc/rpm/macros.image-language-conf

# https://bugzilla.redhat.com/show_bug.cgi?id=1727489
echo 'LANG="C.UTF-8"' >  /etc/locale.conf

# force each container to have a unique machine-id
> /etc/machine-id

# create tmp directories because there is no tmpfs support in Docker
umount /run
systemd-tmpfiles --create --boot

# disable login prompt and mounts
systemctl mask console-getty.service \
               dev-hugepages.mount \
               getty.target \
               systemd-logind.service \
               sys-fs-fuse-connections.mount \
               systemd-remount-fs.service

# remove unnecessary files
rm -f /var/lib/dnf/history.* \
      /run/nologin
rm -fr /var/log/* \
       /tmp/* /tmp/.* \
       /boot || true
%end
