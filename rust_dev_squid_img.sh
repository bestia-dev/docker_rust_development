#!/usr/bin/env bash

echo " "
echo "Bash script to build the docker image for the Squid proxy server"
echo "Name of the image: rust_dev_squid_img"
echo "https://github.com/LucianoBestia/docker_rust_development"

echo "Squid proxy for restricting outbound network access of containers in the same 'pod'."
echo "Modifies the squid.conf file of the official Squid image."
echo "This container is used inside a Podman 'pod' with the container rust_dev_vscode_img"

echo "To build the image, run in bash with:"
echo "sh rust_dev_squid_img.sh"

echo " "
echo "removing container and image if exists"
# Be careful, this container is not meant to have persistent data.
# the '|| :' in combination with 'set -e' means that 
# the error is ignored if the container does not exist.
set -e
buildah rmi -f rust_dev_squid_img || :
buildah rm rust_dev_squid_img || :

echo " "
echo "Create new container named rust_dev_squid_img from sameersbn/squid:latest"
set -o errexit
buildah from --name rust_dev_squid_img docker.io/sameersbn/squid:latest

echo " "
echo "Copy squid.conf"
buildah copy rust_dev_squid_img 'etc_squid_squid.conf' '/etc/squid/squid.conf'

echo " "
echo "Remove unwanted files"
buildah run --user root rust_dev_squid_img    apt -y autoremove
buildah run --user root rust_dev_squid_img    apt -y clean

echo " "
echo "Finally save/commit the image named rust_dev_squid_img"
buildah commit rust_dev_squid_img rust_dev_squid_img

echo " "
echo "To create the 'pod' with 'squid_cnt' and 'rust_dev_cnt' use:"
echo " podman pod create --name rust_dev_pod"
echo " podman pod ls"
echo " podman create --name squid_cnt --pod=rust_dev_pod -ti --restart=always localhost/rust_dev_squid_img"
echo " podman start squid_cnt"
echo " podman create --name rust_dev_cnt --pod=rust_dev_pod -ti rust_dev_vscode_img"
echo " podman start rust_dev_cnt"

echo " "
echo "Firstly: attach VSCode to the running container."
echo "Open VSCode, press F1, type 'attach' and choose 'Remote-Containers:Attach to Running container...' and type rust_dev_cnt" 
echo "This will open a new VSCode windows attached to the container."
echo "If needed Open VSCode terminal with Ctrl+J"
echo "Inside VSCode terminal, try the if the proxy restrictions work:"
echo " curl --proxy 127.0.0.1:3128 http://httpbin.org/ip"
echo " curl --proxy 127.0.0.1:3128 http://google.com"