#!/bin/bash
#
## Controls the switch between 1phase and 3phases using the
#           Rutenbeck TCR IP 4 IP relais.
#
## Wiring
#           You need a 3phase contactor of which only phase 2 and 3 are switched by the contactor.
#           Phase 1 is directly routed to the KEBA P30c wallbox.
#           The 3phase contactor is switched on when relais 2 of the Rutenbeck TCR IP 4 is 
#           switched on.
#
#           KeContact P30c: wire the release input "X1" to relais 4 of the Rutenbeck TCR IP 4.
#
## input parameters:
#           $1 ... command: "1"     ... change to 1 phase
#                           "3"     ... change to 3 phases
#                           "start"/"stop"  ... TODO ... shall be part of u1p3pcheck.sh in my opinion
#
#
#           $2 ... charge point: "lp0..lp8"
#
## Config parameters => todo: move to u1p3pcheck
#           u1p3p_module_lp0=<module_path>
#           u1p3p_module_lp1=<module_path>
#           ...
#           u1p3p_module_lp8=<module_path>
#
#           u1p3p_rutenbeck_keba_ip_lp0=<IpAddress of rutenbeck>||"none"
#           u1p3p_rutenbeck_keba_ip_lp1=<IpAddress of rutenbeck>||"none"
#           ...
#           u1p3p_rutenbeck_keba_ip_lp8=<IpAddress of rutenbeck>||"none"
#
#  e.g. for modules/1p3p_rutenbeck_keba/
#           u1p3p_module_lp0=1p3p_rutenbeck_keba
#
#
## Called by: runs/u1p3pcheck.sh
#
#
## constants
commands=("1" "3")
chargepoints=("lp0" "lp1" "lp2" "lp3" "lp4" "lp5" "lp6" "lp7" "lp8")

rutenbeckPort=30303
response="none"
relaisContactor=2
relaisKebaX1=4
relaisTestReadback=1
relaisReadReadback=3

## functions
# parameter 1: relais number: 1,2,3,4
# parameter 2: "0" ... switch off, "1" ... switch on
function switchRutenbeck() {
    relais=("1" "2" "3" "4")
    actions=("0" "1")
    relaisNumber=$1
    actionNumber=$2
    #check relais number
    if [[ " "${relais[@]}" " == *" "$relaisNumber" "* ]]
    then
        #echo "relais valid"
        #do nothing
        :
    else
        echo "invalid relais number: $relaisNumber"
        exit 5
    fi
    #check action number
    if [[ " "${actions[@]}" " == *" "$actionNumber" "* ]]
    then 
        #echo "action valid"
        #do nothing
        :
    else
        echo "invalid action number: $actionNumber"
        exit 6
    fi
    # send the OUT2 0 command via socat UDP to the IPRelais
    # and remove \r from the received response
    response=$(echo -n "OUT$relaisNumber $actionNumber" | socat - UDP-DATAGRAM:$ipAddress:$rutenbeckPort | tr -d '\r')
    #echo "Response:[$response]"
    if [[ $response == "OUT$relaisNumber =$actionNumber" ]]
    then
        #echo "action: $actionNumber successful"
        #do nothing
        :
    else
        echo "action: $actionNumber failed"
        exit 7
    fi
}

## variables
command="invalid"
chargepoint="invalid"

### input parameter check ###
# $1 ... command
if [[ " "${commands[@]}" " == *" "$1" "* ]]
then
    #echo "command valid"
    command=$1
else
    echo "Invalid command: $1. Valid values are:"
    echo "${commands[@]/%/,}"

    # exit with invalid first input parameter
    exit 1
fi

# $2 ... chargepoint
if [[ " "${chargepoints[@]}" " == *" "$2" "* ]]
then
    #echo "chargepoint valid"
    chargepoint=$2
else
    echo "Invalid chargepoint $2. Valid values are:"
    echo "${chargepoints[@]/%/,}"

    # exit with invalid second input parameter
    exit 2
fi
#test begin
u1p3p_rutenbeck_keba_ip_lp0="192.168.15.18"
#u1p3p_rutenbeck_keba_ip_lp0="1.2.3.4"
#test end

### check chargeoint ip config parameter ###
# concatenate config variable name
chargepoint_ip_variable="u1p3p_rutenbeck_keba_ip_$chargepoint"
#echo "rutenbeck chargepoint ip: $chargepoint_ip_variable"

# read config variable
ipAddress=${!chargepoint_ip_variable}
#echo "ipAddress=$ipAddress"

# check config variable
if [ -z "$ipAddress" ] || [ "none" == "$ipAddress" ]
then
    echo "IpAddress empty or not configured: $ipAddress"
    # exit ip empty or "none"
    exit 3
fi

# simple ip address check
if [[ $ipAddress =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
    #echo "simple ip address check passed"
    #do nothing
    :
else
    echo "ip address is invalid: $ipAddress"
    # exit ip address failed syntax check
    exit 4
fi

### process command ###
case $command in
    "1")
        echo "switch to 1 phase"
        # open X1 on KEBA - block charging
        switchRutenbeck $relaisKebaX1 0
        sleep 1
        # switch to 1 phase
        switchRutenbeck $relaisContactor 0
        sleep 1
        # close X1 on KEBA -free to charge
        switchRutenbeck $relaisKebaX1 1
    ;;
    "3")
        echo "switch to 3 phases"
        # open X1 on KEBA - block charging
        switchRutenbeck $relaisKebaX1 0
        sleep 1
        # switch to 3 phases
        switchRutenbeck $relaisContactor 1
        sleep 1
        # close X1 on KEBA -free to charge
        switchRutenbeck $relaisKebaX1 1
    ;;
    *)
    # should not happen because of input parameter check
    echo "invalid command"
    exit 1
    ;;
esac




