ARG SYSBASE=almalinux

FROM ${SYSBASE} AS system-build

RUN mkdir -p /mnt/sys-root; \
    dnf install --installroot /mnt/sys-root --releasever 8 --setopt install_weak_deps=false --nodocs -y \
    bash \
    binutils \
    coreutils \
    coreutils-common \
    crypto-policies-scripts \
    dbus-glib \
    diffutils \
    dmidecode \
    dnf-plugins-core \
    elfutils-debuginfod-client \
    file \
    findutils \
    glibc-minimal-langpack \
    gzip \
    hwdata \
    iptables-libs \
    iputils \
    jq \
    langpacks-en \
    less \
    libibverbs \
    libmetalink \
    libnl3 \
    libpcap \
    libuser \
    make \
    nano \    
    ncurses \
    openssl \
    openssl-pkcs11 \
    passwd \
    pciutils \
    pciutils-libs \
    platform-python-pip \
    procps-ng \ 
    python3-dateutil \
    python3-dbus \
    python3-dnf-plugins-core \
    python3-six \
    python3-unbound \
    rdma-core \
    rootfiles \
#    rpm-plugin-systemd-inhibit \
    rsyslog \
    sudo \
    systemd \
    tar \
    tmux \
    unbound-libs \
    usermode \
    vim-minimal \
    virt-what \
    which \
    wget \
    xz \
    yum \
    yum-utils;\
    dnf --installroot /mnt/sys-root clean all; \
    rm -rf /mnt/sys-root/var/cache/* /mnt/sys-root/var/log/dnf* /mnt/sys-root/var/log/yum.*; \
    # cp /etc/yum.repos.d/*.repo /mnt/sys-root/etc/yum.repos.d/; \
    # generate build time file for compatibility with CentOS
    /bin/date +%Y%m%d_%H%M > /mnt/sys-root/etc/BUILDTIME; \
    echo '%_install_langs C.utf8' > /mnt/sys-root//etc/rpm/macros.image-language-conf; \
    echo 'LANG="C.utf8"' >  /mnt/sys-root/etc/locale.conf; \
    echo 'container' > /mnt/sys-root/etc/dnf/vars/infra; \
    echo 'PS1="\[\e[m\][\[\e[m\]\[\e[35m\]\u\[\e[m\]\[\e[33m\]@\[\e[m\]\[\e[32m\]\h\[\e[m\]:\[\e[36m\]\w\[\e[m\]\[\e[m\]]\[\e[m\]\\$ "' >> /mnt/sys-root//etc/profile.d/sh.local; \
    echo 'LANG="C.utf8"' >> /mnt/sys-root//etc/profile.d/sh.local; \
    rm -f /mnt/sys-root/etc/machine-id; \
    touch /mnt/sys-root/etc/machine-id;

COPY scripts/ /mnt/sys-root/

FROM scratch AS system-build2

COPY --from=system-build /mnt/sys-root/ /

RUN systemctl set-default multi-user.target; \
    systemctl mask systemd-remount-fs.service \
    dev-hugepages.mount \
    sys-fs-fuse-connections.mount \
    systemd-logind.service \
    getty.target \
    console-getty.service \
    systemd-udev-trigger.service \
    systemd-udevd.service \
    systemd-random-seed.service \
    systemd-machine-id-commit.service
#
# Rebuild frrom scratch to bypass squash option - old docker compatable
FROM scratch 

COPY --from=system-build2 . .

ENV LANG=C.utf8 

STOPSIGNAL SIGRTMIN+3
#
CMD ["/sbin/init"]
#
# Use `--squash` option if gen-rootfs complains about multiple layers.
#
# build image step       : docker build -t srbala/wsl:alma-amd64 .
# test & local run step  : docker run --rm -it srbala/wsl:alma-amd64 /bin/bash
#
# build image step       : docker build --platform linux/arm64 -t srbala/wsl:alma-arm64 .
# test & local run step  : docker run --rm -it srbala/wsl:alma-arm64 /bin/bash
#