#!/bin/bash
#
## Controls the switch between 1phase and 3phases using modbus
#
## input parameters:
#           $1 ... command: "1"     ... change to 1 phase
#                           "3"     ... change to 3 phases
#
#           $2 ... charge point: "1..8"
#
#
## Called by: runs/u1p3pcheck.sh
#
#
## constants
commands=("1" "3")
chargepoints=("1" "2" "3" "4" "5" "6" "7" "8")

# 1p3p switching configured active
u1p3p_active_list=( "1",
                    $u1p3plp2aktiv,
                    $u1p3plp3aktiv,
                    $u1p3plp4aktiv
                    $u1p3plp5aktiv,
                    $u1p3plp6aktiv,
                    $u1p3plp7aktiv,
                    $u1p3plp8aktiv)
u1p3p_active_list_len=${#u1p3p_active_list[@]}

evsecon_list=( $evsecon,    #chargepoint 1
               $evsecons1,  #chargepoint 2
               $evsecons2,  #chargepoint 3
               $evseconlp4, #chargepoint 4
               $evseconlp5, #chargepoint 5
               $evseconlp6, #chargepoint 6
               $evseconlp7, #chargepoint 7
               $evseconlp8) #chargepoint 8

u1p3plpid_list=( $u1p3plp2id, #chargepoint 1 - same as 2!
                 $u1p3plp2id, #chargepoint 2 - same as 1!
                 $u1p3plp3id, #chargepoint 3
                 $u1p3plp4id, #chargepoint 4
                 $u1p3plp5id, #chargepoint 5
                 $u1p3plp6id, #chargepoint 6
                 $u1p3plp7id, #chargepoint 7
                 $u1p3plp8id) #chargepoint 8

## input parameter check ##
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

## check chargeoint ip config parameter ##
# concatenate config variable name
chargepoint_ip_variable="evseiplp${chargepoint}"
#echo "chargepoint ip: $chargepoint_ip_variable"

# read config variable
ipAddress=${!chargepoint_ip_variable}
#echo "ipAddress=$ipAddress"

# check ip variable
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

## process command ##
case $command in
    "1")
        echo "switch to 1 phase"
        if [[ ${evsecon_list[$chargepoint-1]} == "ipevse" && ${u1p3p_active_list[$chargepoint-1]} == "1" ]]
        then
          sudo python runs/u1p3premote.py -a $ipAddress -i ${u1p3plpid_list[$chargepoint-1]} -p 1 -d $u1p3ppause
        fi
    ;;
    "3")
        echo "switch to 3 phases"
        if [[ ${evsecon_list[$chargepoint-1]} == "ipevse" ${u1p3p_active_list[$chargepoint-1]} == "1" ]]
        then
          sudo python runs/u1p3premote.py -a $ipAddress -i ${u1p3plpid_list[$chargepoint-1]} -p 3 -d $u1p3ppause
        fi
    ;;
    *)
    # should not happen because of input parameter check
    echo "invalid command"
    exit 1
    ;;
esac




