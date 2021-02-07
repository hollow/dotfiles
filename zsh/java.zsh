# https://openjdk.java.net/
# open-source implementation of the Java Platform
_brew_install -l openjdk

# make sure the MacOS system wrapper can find openjdk
if [[ "${OSTYPE}" == darwin* ]]; then
    jdk_link="/Library/Java/JavaVirtualMachines/openjdk.jdk"
    jdk_brew="/usr/local/opt/openjdk/libexec/openjdk.jdk"
    if [[ "$(readlink "${jdk_link}")" != "${jdk_brew}" ]]; then
        sudo ln -nfs "${jdk_brew}" "${jdk_link}"
    fi
fi
