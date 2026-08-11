#!/usr/bin/env bash
#
# NexoraOS — automated_script.sh
# Standard archiso helper that runs an arbitrary script passed via the
# `script=` kernel cmdline parameter, or via the `automated_script` variable.
# Used by both CI smoke-tests and end-user auto-installs.

script_cmdline() {
    local script
    for script in $(cat /proc/cmdline); do
        case "${script}" in
            script=*)
                printf '%s\n' "${script#*=}"
                return 0
                ;;
        esac
    done
    printf '%s\n' "${automated_script:-}"
}

 automated_script() {
    local script rt
    script="$(script_cmdline)"
    if [[ -n "${script}" && -x /root/customize_airootfs.sh ]]; then
        # download or read local
        if [[ "${script}" =~ ^((http|https|ftp)://) ]]; then
            curl -fsSL "${script}" --output /root/automated_script.sh
            rt=$?
        else
            cp "${script}" /root/automated_script.sh
            rt=$?
        fi
        if [[ ${rt} -eq 0 ]]; then
            chmod +x /root/automated_script.sh
            /root/automated_script.sh
        fi
    fi
}

if [[ $(tty) == "/dev/tty1" ]]; then
    automated_script
fi
