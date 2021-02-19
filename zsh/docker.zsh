# https://www.docker.com/products/docker-desktop
# Docker Desktop for Mac
if [[ "${OSTYPE}" == darwin* ]]; then
    _cask_install docker
fi

# make sure docker adheres to XDG
export DOCKER_CONFIG="${XDG_CONFIG_HOME}"/docker

# https://github.com/bcicen/ctop
# top-like interface for container metrics
_brew_install ctop
