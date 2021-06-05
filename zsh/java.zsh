# https://openjdk.java.net/
# open-source implementation of the Java Platform
if [[ "${OSTYPE}" == darwin* ]]; then
    jdk_link="/Library/Java/JavaVirtualMachines/openjdk.jdk"
    jdk_brew="${HOMEBREW_PREFIX}/opt/openjdk/libexec/openjdk.jdk"
    if [[ "$(readlink "${jdk_link}")" != "${jdk_brew}" ]]; then
        sudo ln -nfs "${jdk_brew}" "${jdk_link}"
    fi
fi
