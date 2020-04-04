#!/usr/bin/env bash

set -o errexit -o noclobber -o nounset -o pipefail

get_used_spectrum () {

  CENTER_FREQ=$(snmpget -v1 -c ${COMMUNITY} ${HOST} .1.3.6.1.4.1.41112.1.4.1.1.4.1)
  CENTER_FREQ=${CENTER_FREQ#'SNMPv2-SMI::enterprises.41112.1.4.1.1.4.1 = INTEGER: '}

  CHAN_BW=$(snmpget -v1 -c ${COMMUNITY} ${HOST} 1.3.6.1.4.1.41112.1.4.5.1.14.1)
  CHAN_BW=${CHAN_BW#'SNMPv2-SMI::enterprises.41112.1.4.5.1.14.1 = INTEGER: '}

  SSID=$(snmpget -v1 -c ${COMMUNITY} ${HOST} .1.3.6.1.4.1.41112.1.4.5.1.2.1)
  SSID=${SSID#'SNMPv2-SMI::enterprises.41112.1.4.5.1.2.1 = STRING: '}

  #echo ${CENTER_FREQ}
  #echo ${CHAN_BW}

  DELTA=$((${CHAN_BW} / 2))
  START=$((${CENTER_FREQ} - ${DELTA}))
  END=$((${CENTER_FREQ} + ${DELTA}))

  echo "{ \"name\": ${SSID}, \"start\": ${START}, \"end\": ${END} },"
}

main () {
  echo "["
  for HOST in ${HOSTS}
  do
    get_used_spectrum
  done
  echo "]"
}

usage () {
  echo "spectrum [-c|community] HOST [HOSTS...]"
}

# Process parameters
params="$(getopt -o c:h \
    -l community,help \
    --name "spectrum" -- "$@")"

if [ $? -ne 0 ]
then
    usage
fi

eval set -- "$params"
unset params

while true
do
    case $1 in
        -c|--community)
            COMMUNITY=(${2-})
            shift 2
            ;;
        -h|--help)
            usage
            exit
            ;;
        --)
            shift
            if [ -z "${1:-}" ]
            then
                echo "Missing targets."
                break
            fi
            HOSTS=$@
            break;
            ;;
        *)
            echo "Help!"
            break;
            ;;
    esac
done

main
