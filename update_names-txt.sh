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
ALLOW_INSECURE_SSL="true"
CURL_RETRY="--connect-timeout 15 --max-time 60 --retry 3 --retry-delay 5 --silent --show-error"
# ========= CODE STARTS HERE =========

ORIGINAL_SCRIPT_PATH="${0}"
[[ "${ORIGINAL_SCRIPT_PATH}" == "bash" ]] && \
	ORIGINAL_SCRIPT_PATH="$(ps -o comm,pid | awk -v PPID=${PPID} '$2 == PPID {print $1}')"

INI_PATH="${ORIGINAL_SCRIPT_PATH%.*}.ini"

if [ -f "${INI_PATH}" ] ; then
    TMP=$(mktemp)
    dos2unix < "${INI_PATH}" 2> /dev/null | grep -v "^exit" > ${TMP} || true

    if [ $(grep -c "ALLOW_INSECURE_SSL=" "${TMP}") -gt 0 ] ; then
        ALLOW_INSECURE_SSL=$(grep "ALLOW_INSECURE_SSL=" "${TMP}" | awk -F "=" '{print$2}' | sed -e 's/^ *// ; s/ *$// ; s/^"// ; s/"$//')
    fi 2> /dev/null

    if [ $(grep -c "CURL_RETRY=" "${TMP}") -gt 0 ] ; then
        CURL_RETRY=$(grep "CURL_RETRY=" "${TMP}" | awk -F "=" '{print$2}' | sed -e 's/^ *// ; s/ *$// ; s/^"// ; s/"$//')
    fi 2> /dev/null

    rm ${TMP}
fi

SSL_SECURITY_OPTION=""

set +e
curl ${CURL_RETRY} "https://github.com" > /dev/null 2>&1
RET_CURL=$?
set -e

case ${RET_CURL} in
    0)
        ;;
    *)
        if [[ "${ALLOW_INSECURE_SSL}" == "true" ]]
        then
            SSL_SECURITY_OPTION="--insecure"
        else
            echo "CA certificates need"
            echo "to be fixed for"
            echo "using SSL certificate"
            echo "verification."
            echo "Please fix them i.e."
            echo "using security_fixes.sh"
            exit 2
        fi
        ;;
    *)
        echo "No Internet connection"
        exit 1
        ;;
esac

SCRIPT_NAME="$(basename ${0})"
SCRIPT_PATH="/tmp/${SCRIPT_NAME}"
rm ${SCRIPT_PATH} 2> /dev/null || true

if [[ "${DEBUG_UPDATER:-false}" != "true" ]] ; then
    REPOSITORY_URL=""
    echo "Downloading"
    echo "https://github.com/theypsilon/Names_TXT_Updater_MiSTer"
    echo ""

    curl \
        ${CURL_RETRY} \
        ${SSL_SECURITY_OPTION} \
        --fail \
        --location \
        -o "${SCRIPT_PATH}" \
        "https://raw.githubusercontent.com/theypsilon/Names_TXT_Updater_MiSTer/master/dont_download.sh"
else
    cp dont_download.sh ${SCRIPT_PATH}
    export AUTO_UPDATE_LAUNCHER="false"
    export DEBUG_UPDATER
fi

chmod +x ${SCRIPT_PATH}

export CURL_RETRY
export ALLOW_INSECURE_SSL
export SSL_SECURITY_OPTION
export EXPORTED_0="${0}"

if ! ${SCRIPT_PATH} ; then
    echo "Script ${SCRIPT_NAME} failed!"
    echo
fi

rm ${SCRIPT_PATH}

exit 0
