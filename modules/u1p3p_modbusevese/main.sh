#!/bin/bash
#
## Controls the switch between 1phase and 3phases using modbus
#
## input parameters:
#           $1 ... command: "1"     ... change to 1 phase
#                           "3"     ... change to 3 phases
#
#           $2 ... charge point: "1" (no other chargepoint allowed)
#
#
## Called by: runs/u1p3pcheck.sh
#
#
## constants
commands=("1" "3")
chargepoints=("1")

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

## process command ##
case $command in
    "1")
        echo "switch to 1 phase"
        # chargepoint 1
        if [[ $evsecon == "modbusevse" ]]; then
          openwbDebugLog "MAIN" 0 "Pause nach Umschaltung: ${u1p3ppause}s"
          sudo python runs/trigopen.py -d $u1p3ppause
        fi
        #todo report no match
    ;;
    "3")
        echo "switch to 3 phases"
        if [[ $evsecon == "modbusevse" ]]; then
          openwbDebugLog "MAIN" 0 "Pause nach Umschaltung: ${u1p3ppause}s"
          sudo python runs/trigclose.py -d $u1p3ppause
        fi
        #todo remot no match
    ;;
    *)
    # should not happen because of input parameter check
    echo "invalid command"
    exit 1
    ;;
esac
