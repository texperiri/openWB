#!/bin/bash
# requirements: install shunit2:
# sudo apt-get install shunit2

evseConList=("evsecon" "evsecons1" "evsecons2" "evseconlp4" "evseconlp5" "evseconlp6" "evseconlp7" "evseconlp8")
evseiplpxList=("evseiplp1" "evseiplp2" "evseiplp3" "evseiplp4" "evseiplp5" "evseiplp6" "evseiplp7" "evseiplp8")
evseiplpxValList=("1.1.1.1" "2.2.2.2" "3.3.3.3" "4.4.4.4" "5.5.5.5" "6.6.6.6" "7.7.7.7" "8.8.8.8")
u1p3plpIdList=("u1p3plp2id" "u1p3plp2id" "u1p3plp3id" "u1p3plp4id" "u1p3plp5id" "u1p3plp6id" "u1p3plp7id" "u1p3plp8id")
u1p3plpIdValList=("id1" "id2" "id3" "id4" "id5" "id6" "id7" "id8")
chargepIpList=("chargep1ip" "chargep2ip" "chargep3ip" "chargep4ip" "chargep5ip" "chargep6ip" "chargep7ip" "chargep8ip")
chargeIpValList=("11.11.11.11" "22.22.22.22" "33.33.33.33" "44.44.44.44" "55.55.55.55" "66.66.66.66" "77.77.77.77" "88.88.88.88")
u1p3plpAktivList=("u1p3plp1aktiv" "u1p3plp2aktiv" "u1p3plp3aktiv" "u1p3plp4aktiv" "u1p3plp5aktiv" "u1p3plp6aktiv" "u1p3plp7aktiv" "u1p3plp8aktiv")
lastmanagementList=("lastmanagement0" "lastmanagement" "lastmanagements2" "lastmanagementlp4" "lastmanagementlp5" "lastmanagementlp6" "lastmanagementlp7" "lastmanagementlp8")

# write expected call content to next call file on disk,
# increment next expected call number
writeExpectedCall() {
  local expectedCallCnt=$(<expectedCallCnt.tst)
  echo "$@" > expectedCall_${expectedCallCnt}.tst
  expectedCallCnt=$(($expectedCallCnt+1))
  echo "$expectedCallCnt" > expectedCallCnt.tst
}

# check if real call match the expected calls
checkCalls() {
  expRamDisk=$1
  local expectedCallCnt=$(<expectedCallCnt.tst)
  local callCnt=$(<callCnt.tst)
  assertEquals "CallCounts unequal" "$expectedCallCnt" "$callCnt"
  local maxCalls=$(($callCnt-1))
  for (( call=0; call<$maxCalls; call++ ))
  do
    assertTrue "Call File does not exist 'expectedCall_${call}.tst'" "[ -f 'expectedCall_${call}.tst' ]"
    assertTrue "Call File does not exist 'call_${call}.tst'" "[ -f 'call_${call}.tst' ]"
    local expectedData=$(<expectedCall_${call}.tst)
    local data=$(<call_${call}.tst)
    assertEquals "expected call [${call}] content differs" "$expectedData" "$data"
  done
  ramdiskContent=$(<ramdisk/u1p3pstat)
  assertEquals "RamDisk" "$expRamDisk" "$ramdiskContent"
}

#prepares export and expected results for modbusevse
#writes expected result string into the next expectedCall file
prepareModbusEvse() {
  local chargepoint=$1    #0..7
  local phase=$2          #1,3
  local loadmgmt=$3       #0,1
  local active=$4         #u1p3plpxaktiv 0,1
  local evseconParam=${evseConList[$chargepoint]}
  export $evseconParam="modbusevse"
  local loadmgmtParam=${lastmanagementList[$chargepoint]}
  export $loadmgmtParam="$loadmgmt"
  local activeParam=${u1p3plpAktivList[$chargepoint]}
  export activeParam="$active"
  if [ $chargepoint -eq 0 ]
  then
    writeExpectedCall "openwbDebugLog MAIN 0 Pause nach Umschaltung: 2s"
    if [ $phase -eq 1 ]
    then
      writeExpectedCall "sudo python runs/trigopen.py -d 2"
    else
      writeExpectedCall "sudo python runs/trigclose.py -d 2"
    fi
  fi
}

cleanupEvseConParams() {
  local chargepoint=$1  #0..7
  local evseconParam=${evseConList[$chargepoint]}
  export $evseconParam=""
  local activeParam=${u1p3plpAktivList[$chargepoint]}
  export activeParam="0"
}

prepareIpEvse() {
  local chargepoint=$1  #0..7
  local phase=$2        #1, 3
  local loadmgmt=$3     #0,1
  local active=$4       #u1p3plpxaktiv 0,1
  local evseconParam=${evseConList[$chargepoint]}
  export $evseconParam="ipevse"
  local loadmgmtParam=${lastmanagementList[$chargepoint]}
  export $loadmgmtParam="$loadmgmt"
  local evseIplpx=${evseiplpxList[$chargepoint]}
  local evseIplpxValue=${evseiplpxValList[$chargepoint]}
  export $evseIplpx="$evseIplpxValue"
  local u1p3pId=${u1p3plpIdList[$chargepoint]}
  local u1p3pIdValue=${u1p3plpIdValList[$chargepoint]}
  export $u1p3pId="$u1p3pIdValue"
  local activeParam=${u1p3plpAktivList[$chargepoint]}
  export $activeParam="$active"
  if [ $chargepoint -gt 0 ] && ( [ $active -eq 0 ] || [ $loadmgmt -eq 0 ] )
  then
    : #do nothing
  else
    writeExpectedCall "sudo python runs/u1p3premote.py -a $evseIplpxValue -i $u1p3pIdValue -p $phase -d 2"
  fi
}

prepareExtopenwb() {
  local chargepoint=$1  #0..7
  local phase=$2        #1, 3
  local active=$3       #u1p3plpxaktiv 0,1
  local evseconParam=${evseConList[$chargepoint]}
  #echo "evseconParam=$evseconParam"
  export $evseconParam="extopenwb"
  local loadmgmtParam=${lastmanagementList[$chargepoint]}
  export $loadmgmtParam="$loadmgmt"
  local chargepIp=${chargepIpList[$chargepoint]}
  local chargepIpValue=${chargeIpValList[$chargepoint]}
  export $chargepIp="$chargepIpValue"
  local activeParam=${u1p3plpAktivList[$chargepoint]}
  export $activeParam="$active"
  if [ $chargepoint -gt 0 ] && ( [ $active -eq 0 ] || [ $loadmgmt -eq 0 ] )
  then
    : #do nothing
  else
    writeExpectedCall "mosquitto_pub -r -t openWB/set/isss/U1p3p -h $chargepIpValue -m $phase"
  fi
}

testModbusevse1p3p() {
  for chargepoint in {0..7}
  do
    for phase in 1 3
    do
      for active in 0 1
      do
        for loadmgmt in 0 1
        do
          setUp
          #echo "modbus cp:$(($chargepoint+1)) phase:$phase loadmgmt:$loadmgmt active:$active"
          prepareModbusEvse $chargepoint $phase $loadmgmt $active
          ../u1p3pcheck.sh $phase
          checkCalls $phase
          cleanupEvseConParams $chargepoint
          tearDown
        done
      done
    done
  done
}

testIpEvse1p3p() {
  for chargepoint in {0..7}
  do
    for phase in 1 3
    do
      for active in 0 1
      do
        for loadmgmt in 0 1
        do
          setUp
          #echo "ipevse cp:$(($chargepoint+1)) phase:$phase loadmgmt:$loadmgmt active:$active"
          prepareIpEvse $chargepoint $phase $loadmgmt $active
          ../u1p3pcheck.sh $phase
          checkCalls $phase
          cleanupEvseConParams $chargepoint
          tearDown
        done
      done
    done
  done
}

testExtopenwb1p3p() {
  for chargepoint in {0..7}
  do
    for phase in 1 3
    do
      for active in 0 1
      do
        for loadmgmt in 0 1
        do
          setUp
          #echo "extopenwb cp:$(($chargepoint+1)) phase:$phase loadmgmt:$loadmgmt active:$active"
          prepareExtopenwb $chargepoint $phase $loadmgmt $active
          ../u1p3pcheck.sh $phase
          checkCalls $phase
          cleanupEvseConParams $chargepoint
          tearDown
        done
      done
    done
  done
}

testCombined1p3p() {
 for chargepoint in {0..5}
  do
    for active in 0 1
    do
      for phase in 1 3
      do
        for loadmgmt in 0 1
        do
          setUp
          prepareModbusEvse $chargepoint $phase $loadmgmt $active
          prepareExtopenwb $(($chargepoint+1)) $phase $loadmgmt $active
          prepareIpEvse $(($chargepoint+2)) $phase $loadmgmt $active
          ../u1p3pcheck.sh $phase
          checkCalls $phase
          cleanupEvseConParams $chargepoint
          cleanupEvseConParams $(($chargepoint+1))
          cleanupEvseConParams $(($chargepoint+2))
          tearDown
        done
      done
    done
  done
}

# overwrite 
openwbDebugLog() {
  local cnt=$(<callCnt.tst)
  echo "openwbDebugLog $@" > call_${cnt}.tst
  cnt=$(($cnt+1))
  echo "$cnt" > callCnt.tst
}

# overwrite
sudo() {
  local cnt=$(<callCnt.tst)
  echo "sudo $@" > call_${cnt}.tst
  cnt=$(($cnt+1))
  echo "$cnt" > callCnt.tst
}

# overwrite
mosquitto_pub() {
  local cnt=$(<callCnt.tst)
  echo "mosquitto_pub $@" > call_${cnt}.tst
  cnt=$(($cnt+1))
  echo "$cnt" > callCnt.tst
}

setUp() {
  #echo "SetUp"
  export u1p3ppause="2"
  export -f openwbDebugLog
  export -f sudo
  export -f mosquitto_pub
  touch expectedCallCnt.tst
  echo "0" > expectedCallCnt.tst

  echo "0" > callCnt.tst
  if [ ! -d "ramdisk" ]
  then
    mkdir ramdisk
  fi
  touch ramdisk/u1p3pstat
}

tearDown() {
  #echo "TearDown"
  if [ -f "callCnt.tst" ]
  then
    rm *.tst
  fi

  if [ -d "ramdisk" ]
  then
    rm -rf ramdisk
  fi
  #unset openwbDebugLog
  #unset sudo
}


#oneTimeSetUp() {
#  socatCallCnt=0
#  touch expectedCallCnt.tst
#  echo "0" > expectedCallCnt.tst
#  echo "OneTimeSetUp"
#}

#oneTimeTearDown() {
  #rm *.tst
#  echo "OneTimeTearDown"
#}


# uncomment to run a dedicated set of tests or a single test
#suite() {
  #suite_addTest testModbusevse1p3p
  #suite_addTest testIpEvse1p3p
  #suite_addTest testExtopenwb1p3p
  #suite_addTest testCombined1p3p

#}

# run unit tests using shunit2
source shunit2
