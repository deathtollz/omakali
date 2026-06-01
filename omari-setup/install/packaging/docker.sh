if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
    [[ -f /etc/apt/keyrings/docker.asc ]] && sudo rm /etc/apt/keyrings/docker.asc
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Docker does not publish packages for kali-rolling.
    # Kali is based on Debian bookworm/trixie, so we pin to bookworm here.
    . /etc/os-release
    if [[ $ID == "kali" ]]; then
        DOCKER_CODENAME="bookworm"
    else
        DOCKER_CODENAME="$VERSION_CODENAME"
    fi

    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF2
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${DOCKER_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF2
fi

sudo apt-get update
omari-pkg-add docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
