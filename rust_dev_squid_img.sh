#!/usr/bin/env bash

echo " "
echo "\033[0;33m    Bash script to build the docker image for the Squid proxy server \033[0m"
echo "\033[0;33m    Name of the image: rust_dev_squid_img \033[0m"
# repository: https://github.com/bestia-dev/docker_rust_development

echo "\033[0;33m    Squid proxy for restricting outbound network access of containers in the same 'pod'. \033[0m"
echo "\033[0;33m    Modifies the squid.conf file of the official Squid image. \033[0m"
echo "\033[0;33m    This container is used inside a Podman 'pod' with the container rust_dev_vscode_img \033[0m"

echo "\033[0;33m    To build the image, run in bash with: \033[0m"
echo "\033[0;33m sh rust_dev_squid_img.sh \033[0m"

echo " "
echo "\033[0;33m    removing container and image if exists \033[0m"
# Be careful, this container is not meant to have persistent data.
# the '|| :' in combination with 'set -e' means that 
# the error is ignored if the container does not exist.
set -e
podman rm -f rust_dev_squid_cnt || :
buildah rm rust_dev_squid_img || :
buildah rmi -f docker.io/bestiadev/rust_dev_squid_img || :

echo " "
echo "\033[0;33m    Create new 'buildah container' named rust_dev_squid_img from sameersbn/squid:latest \033[0m"
set -o errexit
buildah from \
--name rust_dev_squid_img \
docker.io/sameersbn/squid:3.5.27-2

buildah config \
--author=github.com/bestia-dev \
--label name=rust_dev_squid_img \
--label version=squid-3.5.27-2 \
--label source=github.com/bestia-dev/docker_rust_development \
rust_dev_squid_img

echo " "
echo "\033[0;33m    Copy squid.conf \033[0m"
buildah copy rust_dev_squid_img 'etc_squid_squid.conf' '/etc/squid/squid.conf'

echo " "
echo "\033[0;33m    Remove unwanted files \033[0m"
buildah run --user root rust_dev_squid_img    apt -y autoremove
buildah run --user root rust_dev_squid_img    apt -y clean

echo " "
echo "\033[0;33m    Finally save/commit the image named rust_dev_squid_img \033[0m"
buildah commit rust_dev_squid_img docker.io/bestiadev/rust_dev_squid_img:latest

buildah tag docker.io/bestiadev/rust_dev_squid_img:latest docker.io/bestiadev/rust_dev_squid_img:squid-3.5.27-2

echo " "
echo "\033[0;33m    To create the 'pod' with 'rust_dev_squid_cnt' and 'rust_dev_vscode_cnt' use: \033[0m"
echo "\033[0;33m podman pod create --name rust_dev_pod \033[0m"
echo "\033[0;33m podman pod ls \033[0m"
echo "\033[0;33m podman create --name rust_dev_squid_cnt --pod=rust_dev_pod -ti docker.io/bestiadev/rust_dev_squid_img:latest \033[0m"
echo "\033[0;33m podman start rust_dev_squid_cnt \033[0m"
echo "\033[0;33m podman create --name rust_dev_vscode_cnt --pod=rust_dev_pod -ti rust_dev_vscode_img \033[0m"
echo "\033[0;33m podman start rust_dev_vscode_cnt \033[0m"

echo " "
echo "\033[0;33m    Firstly: attach VSCode to the running container. \033[0m"
echo "\033[0;33m Open VSCode, press F1, type 'attach' and choose 'Remote-Containers:Attach to Running container...' and type rust_dev_vscode_cnt \033[0m" 
echo "\033[0;33m    This will open a new VSCode windows attached to the container. \033[0m"
echo "\033[0;33m    If needed Open VSCode terminal with Ctrl+J \033[0m"
echo "\033[0;33m    Inside VSCode terminal, try the if the proxy restrictions work: \033[0m"
echo "\033[0;33m curl --proxy 127.0.0.1:3128 http://httpbin.org/ip \033[0m"
echo "\033[0;33m curl --proxy 127.0.0.1:3128 http://google.com \033[0m"
