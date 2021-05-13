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


#index into array of expected results
EXP_OPENWB_DEBUG_LOG=0
EXP_SUDO=1
EXP_MOSQUITTO=2
EXP_RAMD_U1P3PSTAT=3

DEBUG_LOG_MODBUS="MAIN 0 Pause nach Umschaltung: 2s"
DEBUG_LOG_NONE=""
SUDO_NONE=""
MOSQUITTO_NONE=""

#prepares export and expected results for modbusevse
#writes expected result string to expected.tst
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
  if [ $chargepoint -ne 0 ]
  then
    echo "$DEBUG_LOG_NONE,$SUDO_NONE,$MOSQUITTO_NONE,$phase" > expected.tst
  elif [ $phase -eq 1 ]
  then
    # write expected parameters to file
    #     debugLog,         sudo cmd                     mosquitto cmd u1p3pstate ramdisk content
    echo "$DEBUG_LOG_MODBUS,python runs/trigopen.py -d 2,$MOSQUITTO_NONE,$phase" > expected.tst
  else
    echo "$DEBUG_LOG_MODBUS,python runs/trigclose.py -d 2,$MOSQUITTO_NONE,$phase" > expected.tst
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
    echo "$DEBUG_LOG_NONE,$SUDO_NONE,$MOSQUITTO_NONE,$phase" > expected.tst
  else
    #     debugLog,         sudo cmd                     mosquitto cmd u1p3pstate ramdisk content
    echo "$DEBUG_LOG_NONE,python runs/u1p3premote.py -a $evseIplpxValue -i $u1p3pIdValue -p $phase -d 2,$MOSQUITTO_NONE,$phase" > expected.tst
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
    echo "$DEBUG_LOG_NONE,$SUDO_NONE,$MOSQUITTO_NONE,$phase" > expected.tst
  else
    echo "$DEBUG_LOG_NONE,$SUDO_NONE,-r -t openWB/set/isss/U1p3p -h $chargepIpValue -m $phase,$phase" > expected.tst
  fi
}

checkExpected() {
  local paramString=$1  #params returned by "prepare"
  local callCntDebugLog=$2      #defines the file number to read for check, -1 if ignore file
  local callCntSudo=$3
  local callCntMosquitto=$4
  #split testParams string separated by "," into array of strings
  IFS=',' read -r -a params <<< "$paramString"
  local callContent=""
  if [ -f openwbDebugLog_${callCntDebugLog}.tst ]
  then
    callContent=$(<openwbDebugLog_${callCntDebugLog}.tst)
  fi
  local expOpenWbDebugLog=${params[$EXP_OPENWB_DEBUG_LOG]}
  assertEquals "$expOpenWbDebugLog" "$callContent"
  callContent=""
  if [ -f sudo_${callCntSudo}.tst ]
  then
    callContent=$(<sudo_${callCntSudo}.tst)
  fi
  local expSudo=${params[$EXP_SUDO]}
  assertEquals "$expSudo" "$callContent"
  callContent=""
  if [ -f mosquitto_pub_${callCntMosquitto}.tst ]
  then
    callContent=$(<mosquitto_pub_${callCntMosquitto}.tst)
  fi
  local expMosquitto=${params[$EXP_MOSQUITTO]}
  assertEquals "$expMosquitto" "$callContent"
  callContent=$(<ramdisk/u1p3pstat)
  local expRamDU1p3pStat=${params[$EXP_RAMD_U1P3PSTAT]}
  assertEquals "$expRamDU1p3pStat" "$callContent"
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
          expected=$(<expected.tst)
          ../u1p3pcheck.sh $phase
          checkExpected "$expected" 0 0 0
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
          expected=$(<expected.tst)
          ../u1p3pcheck.sh $phase
          checkExpected "$expected" 0 0 0
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
          expected=$(<expected.tst)
          ../u1p3pcheck.sh $phase
          checkExpected "$expected" 0 0 0
          cleanupEvseConParams $chargepoint
          tearDown
        done
      done
    done
  done
}

checkCombined() {
  #todo: use string as parameters
  chargepoint=$1
  phase=$2
  loadmgmt=$3
  active=$4
  modDbg=$5
  modSudo=$6
  modMosq=$7
  ipDbg=$8
  ipSudo=$9
  ipMosq=$10
  wbDbg=$11
  wbSudo=$12
  wbMosq=$13
  prepareModbusEvse $chargepoint $phase $loadmgmt $active
  expectedModbus=$(<expected.tst)
  prepareIpEvse $(($chargepoint+1)) $phase $loadmgmt $active
  expectedIp=$(<expected.tst)
  prepareExtopenwb $(($chargepoint+2)) $phase $loadmgmt $active
  expectedExtOpenwb=$(<expected.tst)
  ../u1p3pcheck.sh $phase
  echo "modbus"
  checkExpected "$expectedModbus" $modDbg $modSudo $modMosq
  echo "ip"
  checkExpected "$expectedIp" $ipDbg $ipSudo $ipMosq
  echo "openwb"
  checkExpected "$expectedExtOpenwb" $wbDbg $wbSudo $wbMosq
  cleanupEvseConParams $chargepoint
  cleanupEvseConParams $(($chargepoint+1))
  cleanupEvseConParams $(($chargepoint+2))
}

testCombinedSimple() {
  chargepoint=0
  phase=1
  loadmgmt=1
  active=1
  prepareModbusEvse $chargepoint $phase $loadmgmt $active
  expectedModbus=$(<expected.tst)
  prepareIpEvse $(($chargepoint+1)) $phase $loadmgmt $active
  expectedIp=$(<expected.tst)
  prepareExtopenwb $(($chargepoint+2)) $phase $loadmgmt $active
  expectedExtOpenwb=$(<expected.tst)
  ../u1p3pcheck.sh $phase
  echo "modbus"
  checkExpected "$expectedModbus" 0 0 -1
  echo "ip"
  checkExpected "$expectedIp" 1 1 1
  echo "openwb"
  checkExpected "$expectedExtOpenwb" 2 2 0
}

testCombined1p3p() {
  for chargepoint in {0..5}
  do
    for phase in 1 3
    do
      for active in 0 1
      do
        for loadmgmt in 0 1
        do
          setUp
          echo "combined cp:$(($chargepoint+1)) phase:$phase loadmgmt:$loadmgmt active:$active"
          prepareModbusEvse $chargepoint $phase $loadmgmt $active
          expectedModbus=$(<expected.tst)
          prepareIpEvse $(($chargepoint+1)) $phase $loadmgmt $active
          expectedIp=$(<expected.tst)
          prepareExtopenwb $(($chargepoint+2)) $phase $loadmgmt $active
          expectedExtOpenwb=$(<expected.tst)
          ../u1p3pcheck.sh $phase
          echo "modbus"
          checkExpected "$expectedModbus" 0 0 -1
          echo "ip"
          checkExpected "$expectedIp" -1 1 -1
          echo "openwb"
          checkExpected "$expectedExtOpenwb" -1 2 0
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
  local cnt=$(<openwbDebugLogcnt.tst)
  echo "$@" > openwbDebugLog_${cnt}.tst
  cnt=$(($cnt+1))
  echo "$cnt" > openwbDebugLogcnt.tst
}

# overwrite
sudo() {
  local cnt=$(<sudocnt.tst)
  echo "$@" > sudo_${cnt}.tst
  cnt=$(($cnt+1))
  echo "$cnt" > sudocnt.tst
}

# overwrite
mosquitto_pub() {
  local cnt=$(<mosquittocnt.tst)
  echo "$@" > mosquitto_pub_${cnt}.tst
  cnt=$(($cnt+1))
  echo "$cnt" > mosquittocnt.tst
}

setUp() {
  #echo "SetUp"
  export u1p3ppause="2"
  export -f openwbDebugLog
  export -f sudo
  export -f mosquitto_pub
  echo "0" > openwbDebugLogcnt.tst
  touch openwbDebugLog_0.tst
  echo "0" > sudocnt.tst
  touch sudo_0.tst
  echo "0" > mosquittocnt.tst
  touch mosquitto_pub_0.tst
  if [ ! -d "ramdisk" ]
  then
    mkdir ramdisk
  fi
  touch ramdisk/u1p3pstat
}

tearDown() {
  #echo "TearDown"
  if [ -f "sudocnt.tst" ]
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
#  echo "OneTimeSetUp"
#}

#oneTimeTearDown() {
  #rm *.tst
#  echo "OneTimeTearDown"
#}


# uncomment to run a dedicated set of tests or a single test
suite() {
  #suite_addTest testModbusevse1p3p
  #suite_addTest testIpEvse1p3p
  #suite_addTest testExtopenwb1p3p
  suite_addTest testCombinedSimple
  #suite_addTest testCombined1p3p
}

# run unit tests using shunit2
source shunit2
