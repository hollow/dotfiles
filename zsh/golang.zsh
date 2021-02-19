# https://github.com/golang/go
# The Go programming language
_brew_install go

# make golang adhere to XDG
export GOPATH="${XDG_CACHE_HOME}"/go
_path_add_bin "${GOPATH}"
