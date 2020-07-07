#!/bin/bash
# Copyright (c) 2020 José Manuel Barroso Galindo <theypsilon@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# You can download the latest version of this script from:
# https://github.com/theypsilon/Updater_All_MiSTer

# Version 1.0 - 2020-07-06 - First commit

set -euo pipefail

# ========= OPTIONS ==================
NAMES_REGION="US"
NAMES_CHAR_CODE="CHAR18"
NAMES_SORT_CODE="Common"
AUTOREBOOT="true"
# ========= CODE STARTS HERE =========
INI_PATH="$(pwd)/update_names-txt.ini"

run_names_updater() {

    echo "Executing 'Names TXT Updater' script"
    echo "Enjoy better core names thanks to community curated names.txt files"
    echo
    echo "Contribute to the naming at:"
    echo "https://github.com/ThreepwoodLeBrush/Names_MiSTer"
    echo

    echo "Reading INI file:"
    if [ -f "${INI_PATH}" ] ; then
        echo "OK"
        local TMP=$(mktemp)
        dos2unix < "${INI_PATH}" 2> /dev/null | grep -v "^exit" > ${TMP} || true
        read_ini_option "NAMES_REGION" "${TMP}"
        read_ini_option "NAMES_CHAR_CODE" "${TMP}"
        read_ini_option "NAMES_SORT_CODE" "${TMP}"
        read_ini_option "AUTOREBOOT" "${TMP}"
        rm ${TMP}
    else
        echo "Not found."
    fi
    echo

    local TMP_NAMES="/tmp/ua_names.txt"
    rm "${TMP_NAMES}" 2> /dev/null || true

    if [[ "${NAMES_CHAR_CODE}" == "CHAR28" ]] && [[ "${NAMES_SORT_CODE}" == "Common" ]] ; then
        NAMES_SORT_CODE="Manufacturer"
    fi

    set +e
    curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -o "${TMP_NAMES}" "https://raw.githubusercontent.com/ThreepwoodLeBrush/Names_MiSTer/master/names_${NAMES_CHAR_CODE}_${NAMES_SORT_CODE}_${NAMES_REGION}.txt"
    local RET_CURL=$?
    set -e

    if [ ${RET_CURL} -ne 0 ] ; then
        echo "Couldn't download names.txt : Network Problem"
        exit 1
    fi

    local REBOOT_NEEDED="false"
    if ! diff "${TMP_NAMES}" "/media/fat/names.txt" > /dev/null 2>&1 ; then
        cp "${TMP_NAMES}" "/media/fat/names.txt"
        echo "Downloaded new names.txt"
        echo
        echo "Region Code: ${NAMES_REGION}"
        echo "Char Code: ${NAMES_CHAR_CODE}"
        echo "Sort Code: ${NAMES_SORT_CODE}"
        echo
        echo "SUCCESS!"
        REBOOT_NEEDED="true"
    else
        echo "No changes detected."
        echo
        echo "Skipping names.txt..."
    fi
    echo
    if [[ "${REBOOT_NEEDED}" == "true" ]] ; then
        touch /tmp/ua_reboot_needed
        local REBOOT_PAUSE=10
        if [[ "${AUTOREBOOT}" == "true" ]] ; then
            echo "Rebooting in ${REBOOT_PAUSE} seconds"
            sleep "${REBOOT_PAUSE}"
            reboot now
        else
            echo "You should reboot to apply the new names.txt"
            echo
        fi
    fi
}

read_ini_option() {
    local INI_OPTION="${1}"
    local INI_FILE="${2}"

    declare -n SCRIPT_OPTION="${INI_OPTION}"

    if [ $(grep -c "${INI_OPTION}=" "${INI_FILE}") -gt 0 ] ; then
        SCRIPT_OPTION=$(grep "${INI_OPTION}=" "${INI_FILE}" | awk -F "=" '{print$2}' | sed -e 's/^ *// ; s/ *$// ; s/^"// ; s/"$//')
    fi 2> /dev/null
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    run_names_updater
fi
