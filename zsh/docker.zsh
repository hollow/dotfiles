# https://www.docker.com/products/docker-desktop
# Docker Desktop for Mac
if [[ "${OSTYPE}" == darwin* ]]; then
    _cask_install docker
fi

# https://github.com/bcicen/ctop
# top-like interface for container metrics
_brew_install ctop
