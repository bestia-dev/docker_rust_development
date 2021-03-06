#!/usr/bin/env bash

# README:

echo " "
echo "\033[0;33m    Bash script to build the docker image for development in Rust. \033[0m"
echo "\033[0;33m    Name of the image: rust_dev_cargo_img \033[0m"
# repository: https://github.com/bestia-dev/docker_rust_development

echo " "
echo "\033[0;33m    I want a sandbox that cannot compromise my local system. \033[0m"
echo "\033[0;33m    No shared volumes. All the files and folders will be inside the container.  \033[0m"
echo "\033[0;33m    The original source code files will be cloned from github or copied from the local system. \033[0m"
echo "\033[0;33m    The final source code files will be pushed to github or copied to the local system. \033[0m"
echo "\033[0;33m    I want also to limit the network ports and addresses inbound and outbound. \033[0m"

echo " "
echo "\033[0;33m    FIRST !!! \033[0m"
echo "\033[0;33m    Search and replace in this bash script: \033[0m"
echo "\033[0;33m    Version of rustc: 1.62.0 \033[0m"
echo "\033[0;33m    Version of rustup: 1.25.1 \033[0m"

echo " "
echo "\033[0;33m    To build the image, run in bash with: \033[0m"
echo "\033[0;33m sh rust_dev_cargo_img.sh \033[0m"

# Start of script actions:

echo " "
echo "\033[0;33m    Removing container and image if exists \033[0m"
# Be careful, this container is not meant to have persistent data.
# the '|| :' in combination with 'set -e' means that 
# the error is ignored if the container does not exist.
set -e
podman rm rust_dev_cargo_cnt || :
buildah rm rust_dev_cargo_img || :
buildah rmi -f docker.io/bestiadev/rust_dev_cargo_img || :


echo " "
echo "\033[0;33m    Create new 'buildah container' named rust_dev_cargo_img \033[0m"
set -o errexit
buildah from --name rust_dev_cargo_img docker.io/library/debian:bullseye-slim


buildah config \
--author=github.com/bestia-dev \
--label name=rust_dev_cargo_img \
--label version=cargo-1.62.0 \
--label source=github.com/bestia-dev/docker_rust_development \
rust_dev_cargo_img

echo " "
echo "\033[0;33m    apk update \033[0m"
buildah run rust_dev_cargo_img    apt -y update
buildah run rust_dev_cargo_img    apt -y full-upgrade

echo " "
echo "\033[0;33m    Install curl, git, rsync and build-essential with root user \033[0m"
# curl is the most used CLI for getting stuff from internet
buildah run rust_dev_cargo_img    apt install -y curl
# git is the legendary source control system
buildah run rust_dev_cargo_img    apt install -y git
# rsync is great for copying files and folders
buildah run rust_dev_cargo_img    apt install -y rsync
# rust needs the C stuff that comes with build-essential
buildah run rust_dev_cargo_img    apt install -y build-essential
# nano is the default easy to use text editor in Debian
buildah run rust_dev_cargo_img    apt install -y nano
# ps displays information about a selection of the active processes
# concretely it is used to run the ssh-agent
buildah run rust_dev_cargo_img    apt install -y procps
# pkg-config and libssl-dev are needed by the crate reqwest to work with TLS/SSL
buildah run rust_dev_cargo_img    apt install -y pkg-config
buildah run rust_dev_cargo_img    apt install -y libssl-dev

echo " "
echo "\033[0;33m    Create non-root user 'rustdevuser' and home folder. \033[0m"
buildah run rust_dev_cargo_img    useradd -ms /bin/bash rustdevuser

echo " "
echo "\033[0;33m    Use rustdevuser for all subsequent commands. \033[0m"
buildah config --user rustdevuser rust_dev_cargo_img
buildah config --workingdir /home/rustdevuser rust_dev_cargo_img

# If needed, the user can be forced for a buildah command:
# buildah run  --user root rust_dev_cargo_img    apt install -y --no-install-recommends build-essential

echo " "
echo "\033[0;33m    Configure rustdevuser things \033[0m"
buildah run rust_dev_cargo_img /bin/sh -c 'mkdir -vp ~/rustprojects'
buildah run rust_dev_cargo_img /bin/sh -c 'mkdir -vp ~/.ssh'
buildah run rust_dev_cargo_img /bin/sh -c 'chmod 700 ~/.ssh'

echo " "
echo "\033[0;33m    Kill auto-completion horrible sound \033[0m"
buildah run rust_dev_cargo_img /bin/sh -c 'echo "set bell-style none" >> ~/.inputrc'

echo " "
echo "\033[0;33m    Install rustup and default x86_64-unknown-linux-gnu, cargo, std, rustfmt, clippy, docs, rustc,...  \033[0m"
buildah run rust_dev_cargo_img /bin/sh -c 'curl https://sh.rustup.rs -sSf | sh -s -- -yq'

echo "\033[0;33m    Rustup wants to add the ~/.cargo/bin to PATH. But it needs to force bash reboot and that does not work in buildah. \033[0m"
echo "\033[0;33m    Add the PATH to ~/.cargo/bin manually \033[0m"
OLDIMAGEPATH=$(buildah run rust_dev_cargo_img printenv PATH)
buildah config --env PATH=/home/rustdevuser/.cargo/bin:$OLDIMAGEPATH rust_dev_cargo_img
buildah run rust_dev_cargo_img /bin/sh -c 'echo $PATH'

buildah run rust_dev_cargo_img /bin/sh -c 'rustup --version'
# rustup 1.25.1 

buildah run rust_dev_cargo_img /bin/sh -c '/home/rustdevuser/.cargo/bin/rustc --version'
# rustc 1.62.0 

# this probably is not necessary, if rust-analyzer can call rust-lang.org
# buildah config --env RUST_SRC_PATH=/home/rustdevuser/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/library rust_dev_cargo_img
# buildah run rust_dev_cargo_img /bin/sh -c 'echo $RUST_SRC_PATH'

buildah run rust_dev_cargo_img /bin/sh -c 'rustup component add rust-src'

echo "\033[0;33m    remove the toolchain docs, because they are 610MB big \033[0m"
buildah run rust_dev_cargo_img /bin/sh -c 'rm -rf /home/rustdevuser/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/share/doc'

echo " "
echo "\033[0;33m    Install cargo-auto. It will pull the cargo-index registry. The first pull can take some time. \033[0m"
buildah run rust_dev_cargo_img /bin/sh -c 'cargo install cargo-auto'
echo "\033[0;33m    Install wasm pack \033[0m"
buildah run rust_dev_cargo_img /bin/sh -c 'curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh'
buildah run rust_dev_cargo_img /bin/sh -c 'cargo install dev_bestia_cargo_completion'

echo " "
echo "\033[0;33m    Add line dev_bestia_cargo_completion to .bashrc \033[0m"
buildah run rust_dev_cargo_img /bin/sh -c 'echo "# dev_bestia_cargo_completion" >> ~/.bashrc'
buildah run rust_dev_cargo_img /bin/sh -c 'echo "complete -C dev_bestia_cargo_completion cargo" >> ~/.bashrc'
echo "\033[0;33m    Add ssh-agent to .bashrc, because it does not work in .bash_profile \033[0m"
buildah copy rust_dev_cargo_img 'bash_profile.conf' '/home/rustdevuser/.ssh/bash_profile.conf'
buildah run rust_dev_cargo_img /bin/sh -c 'cat /home/rustdevuser/.ssh/bash_profile.conf >> ~/.bashrc'

echo " "
echo "\033[0;33m    Remove unwanted files \033[0m"
buildah run --user root rust_dev_cargo_img    apt -y autoremove
buildah run --user root rust_dev_cargo_img    apt -y clean

echo " "
echo "\033[0;33m    Finally save/commit the image named rust_dev_cargo_img \033[0m"
buildah commit rust_dev_cargo_img docker.io/bestiadev/rust_dev_cargo_img:latest
buildah tag docker.io/bestiadev/rust_dev_cargo_img:latest docker.io/bestiadev/rust_dev_cargo_img:cargo-1.62.0

echo " "
echo "\033[0;33m    Upload the new image to docker hub. \033[0m"
echo "\033[0;33m    First you need to store the credentials with: \033[0m"
echo "\033[0;33m podman login --username bestiadev docker.io \033[0m"
echo "\033[0;33m    then type docker access token. \033[0m"
echo "\033[0;33m podman push docker.io/bestiadev/rust_dev_cargo_img:cargo-1.62.0 \033[0m"
echo "\033[0;33m podman push docker.io/bestiadev/rust_dev_cargo_img:latest \033[0m"

echo " "
echo "\033[0;33m    To create the container 'rust_dev_cargo_cnt' use: \033[0m"
echo "\033[0;33m podman create -ti --name rust_dev_cargo_cnt docker.io/bestiadev/rust_dev_cargo_img:latest \033[0m"
echo "\033[0;33m podman restart rust_dev_cargo_cnt \033[0m"
echo "\033[0;33m podman exec -it rust_dev_cargo_cnt bash \033[0m"

echo " "
echo "\033[0;33m    Try to build and run a sample Rust project: \033[0m"
echo "\033[0;33m cargo new rust_dev_hello \033[0m"
echo "\033[0;33m cd rust_dev_hello \033[0m"
echo "\033[0;33m cargo run \033[0m"

echo " "
echo "\033[0;33m    Detach container (it will remain 'started') with: \033[0m"
echo "\033[0;33m Ctrl+P, Ctrl+Q \033[0m"

echo " "
echo "\033[0;33m    To Exit/Stop the container type: \033[0m"
echo "\033[0;33m exit \033[0m"
