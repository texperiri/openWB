#!/bin/bash
# requirements: install shunit2:
# sudo apt-get install shunit2

testDir="testfiles/"
scriptDir="../runs/"
expectedCallCntFile="${testDir}expectedCallCnt.tst"
callCntFile="${testDir}callCnt.tst"

minimalapv="11"
u1p3ppause="2"


evseConList=("evsecon" "evsecons1" "evsecons2" "evseconlp4" "evseconlp5" "evseconlp6" "evseconlp7" "evseconlp8")
evseiplpxList=("evseiplp1" "evseiplp2" "evseiplp3" "evseiplp4" "evseiplp5" "evseiplp6" "evseiplp7" "evseiplp8")
evseiplpxValList=("1.1.1.1" "2.2.2.2" "3.3.3.3" "4.4.4.4" "5.5.5.5" "6.6.6.6" "7.7.7.7" "8.8.8.8")
u1p3plpIdList=("u1p3plp2id" "u1p3plp2id" "u1p3plp3id" "u1p3plp4id" "u1p3plp5id" "u1p3plp6id" "u1p3plp7id" "u1p3plp8id")
u1p3plpIdValList=("id1" "id2" "id3" "id4" "id5" "id6" "id7" "id8")
chargepIpList=("chargep1ip" "chargep2ip" "chargep3ip" "chargep4ip" "chargep5ip" "chargep6ip" "chargep7ip" "chargep8ip")
chargeIpValList=("11.11.11.11" "22.22.22.22" "33.33.33.33" "44.44.44.44" "55.55.55.55" "66.66.66.66" "77.77.77.77" "88.88.88.88")
u1p3plpAktivList=("u1p3plp1aktiv" "u1p3plp2aktiv" "u1p3plp3aktiv" "u1p3plp4aktiv" "u1p3plp5aktiv" "u1p3plp6aktiv" "u1p3plp7aktiv" "u1p3plp8aktiv")
lastmanagementList=("lastmanagement0" "lastmanagement" "lastmanagements2" "lastmanagementlp4" "lastmanagementlp5" "lastmanagementlp6" "lastmanagementlp7" "lastmanagementlp8")
llsollList=("llsoll" "llsolls1" "llsolls2" "llsolllp4" "llsolllp5" "llsolllp6" "llsolllp7" "llsolllp8")
llsollValList=("10" "20" "30" "40" "50" "60" "70" "80")
tmpllsollList=("tmpllsoll" "tmpllsolls1" "tmpllsolls2" "tmpllsolllp4" "tmpllsolllp5" "tmpllsolllp6" "tmpllsolllp7" "tmpllsolllp8")
setCurrentlpList=("m" "s1" "s2" "lp4" "lp5" "lp6" "lp7" "lp8")

# write expected call content to next call file on disk,
# increment next expected call number
writeExpectedCall() {
  local expectedCallCnt=$(<${expectedCallCntFile})
  echo "$@" > "${testDir}expectedCall_${expectedCallCnt}.tst"
  expectedCallCnt=$(($expectedCallCnt+1))
  echo "$expectedCallCnt" > $expectedCallCntFile
}

writeExpectedRamDisk() {
  local fileName=$1
  local expFileContent=$2
  echo $expFileContent > ramdisk/"expected_${fileName}"
}

# check if real call match the expected calls
checkCalls() {
  local expectedCallCnt=$(<${expectedCallCntFile})
  local callCnt=$(<${callCntFile})
  assertEquals "CallCounts unequal" "$expectedCallCnt" "$callCnt"
  for (( call=0; call<$callCnt; call++ ))
  do
    assertTrue "Call File does not exist '${testDir}expectedCall_${call}.tst'" "[ -f '${testDir}expectedCall_${call}.tst' ]"
    assertTrue "Call File does not exist '${testDir}call_${call}.tst'" "[ -f '${testDir}call_${call}.tst' ]"
    local expectedData=$(<${testDir}expectedCall_${call}.tst)
    #echo "expectedData=${expectedData}"
    local data=$(<${testDir}call_${call}.tst)
    #echo "data=${data}"
    assertEquals "expected call [${call}] content differs" "$expectedData" "$data"
  done
  if [ -f "ramdisk/expected_u1p3pstat" ]
  then
    local expRamDisk=$(<ramdisk/expected_u1p3pstat)
    local ramdiskContent=$(<ramdisk/u1p3pstat)
    assertEquals "RamDisk-u1p3pstat" "$expRamDisk" "$ramdiskContent"
  elif [ -f "ramdisk/u1p3pstat" ]
  then
    fail "ramdisk/u1p3pstat exists but not expected to exist"
  fi
}

cleanupEvseConParams() {
  local chargepoint=$1  #0..7
  local evseconParam=${evseConList[$chargepoint]}
  export $evseconParam=""
  local activeParam=${u1p3plpAktivList[$chargepoint]}
  export activeParam="0"
}

exportBaseParams() {
  local chargepoint=$1
  local evseType=$2
  local loadmgmt=$3
  local active=$4
  local evseconParam=${evseConList[$chargepoint]}
  export $evseconParam=$evseType
  local loadmgmtParam=${lastmanagementList[$chargepoint]}
  export $loadmgmtParam="$loadmgmt"
  local activeParam=${u1p3plpAktivList[$chargepoint]}
  export $activeParam="$active"
  local evseIplpx=${evseiplpxList[$chargepoint]}
  local evseIplpxValue=${evseiplpxValList[$chargepoint]}
  export $evseIplpx="$evseIplpxValue"
  local u1p3pId=${u1p3plpIdList[$chargepoint]}
  local u1p3pIdValue=${u1p3plpIdValList[$chargepoint]}
  export $u1p3pId="$u1p3pIdValue"
  local chargepIp=${chargepIpList[$chargepoint]}
  local chargepIpValue=${chargeIpValList[$chargepoint]}
  export $chargepIp="$chargepIpValue"
}

#prepares export and expected results for modbusevse
#writes expected result string into the next expectedCall file
prepareModbusEvse() {
  local chargepoint=$1    #0..7
  local cmd=$2          #1,3,start,stop
  local loadmgmt=$3       #0,1
  local active=$4         #u1p3plpxaktiv 0,1
  exportBaseParams $chargepoint "modbusevse" $loadmgmt $active
  if [ $cmd = "1" ] || [ $cmd = "3" ]
  then
    writeExpectedRamDisk "u1p3pstat" "$cmd"
  fi
  case $cmd in
    "1")
      if [ $chargepoint -eq 0 ]
      then
        writeExpectedCall "openwbDebugLog MAIN 0 Pause nach Umschaltung: 2s"
        writeExpectedCall "sudo python runs/trigopen.py -d 2 -c 1"
      fi
      if ( [ $chargepoint -eq 1 ] && [ $loadmgmt -eq 1 ] && [ $active -eq 1 ] )
      then
        writeExpectedCall "openwbDebugLog MAIN 0 Pause nach Umschaltung: 2s"
        writeExpectedCall "sudo python runs/trigopen.py -d 2 -c 2"
      fi
      ;;
    "3")
      if [ $chargepoint -eq 0 ]
      then
        writeExpectedCall "openwbDebugLog MAIN 0 Pause nach Umschaltung: 2s"
        writeExpectedCall "sudo python runs/trigclose.py -d 2 -c 1"
      fi
      if ( [ $chargepoint -eq 1 ] && [ $loadmgmt -eq 1 ] && [ $active -eq 1 ] )
      then
        writeExpectedCall "openwbDebugLog MAIN 0 Pause nach Umschaltung: 2s"
        writeExpectedCall "sudo python runs/trigclose.py -d 2 -c 2"
      fi
      ;;
    "stop")
      if [ $chargepoint -eq 0 ] || ( [ $chargepoint -eq 1 ] && [ $loadmgmt -eq 1 ] && [ $active -eq 1 ] )
      then
        writeExpectedCall "runs/set-current.sh 0 ${setCurrentlpList[$chargepoint]}"
        echo "${llsollValList[$chargepoint]}" > ramdisk/${llsollList[$chargepoint]}
        writeExpectedRamDisk "tmpllsoll" "${llsollValList[$chargepoint]}"
      fi
      ;;
    "start")
      if [ $chargepoint -eq 0 ] || ( [ $chargepoint -eq 1 ] && [ $loadmgmt -eq 1 ] && [ $active -eq 1 ] )
      then
        writeExpectedCall "runs/set-current.sh ${llsollValList[$chargepoint]} ${setCurrentlpList[$chargepoint]}"
        echo "${llsollValList[$chargepoint]}" > ramdisk/${tmpllsollList[$chargepoint]}
      fi
      ;;
    "startslow")
      if [ $chargepoint -eq 0 ] || ( [ $chargepoint -eq 1 ] && [ $loadmgmt -eq 1 ] && [ $active -eq 1 ] )
      then
        writeExpectedCall "runs/set-current.sh ${minimalapv} ${setCurrentlpList[$chargepoint]}"
      fi
      ;;
    *)
      fail "invalid command: [$cmd]"
      ;;
  esac
}

prepareIpEvse() {
  local chargepoint=$1  #0..7
  local cmd=$2        #1, 3, start, stop, startslow
  local loadmgmt=$3     #0,1
  local active=$4       #u1p3plpxaktiv 0,1
  exportBaseParams $chargepoint "ipevse" $loadmgmt $active

  local evseIplpxValue=${evseiplpxValList[$chargepoint]}
  local u1p3pIdValue=${u1p3plpIdValList[$chargepoint]}

  if [ $cmd = "1" ] || [ $cmd = "3" ]
  then
    writeExpectedRamDisk "u1p3pstat" "$cmd"
  fi
  
  if [ $chargepoint -gt 0 ] && ( [ $active -eq 0 ] || [ $loadmgmt -eq 0 ] )
  then
    : #do nothing
  else
    case $cmd in
      "1"|"3")
        writeExpectedCall "sudo python runs/u1p3premote.py -a $evseIplpxValue -i $u1p3pIdValue -p $cmd -d 2"
        ;;
      "stop")
        writeExpectedCall "runs/set-current.sh 0 ${setCurrentlpList[$chargepoint]}"
        echo "${llsollValList[$chargepoint]}" > ramdisk/${llsollList[$chargepoint]}
        writeExpectedRamDisk "tmpllsoll" "${llsollValList[$chargepoint]}"
        ;;
      "start")
        writeExpectedCall "runs/set-current.sh ${llsollValList[$chargepoint]} ${setCurrentlpList[$chargepoint]}"
        echo "${llsollValList[$chargepoint]}" > ramdisk/${tmpllsollList[$chargepoint]}
        ;;
      "startslow")
        writeExpectedCall "runs/set-current.sh ${minimalapv} ${setCurrentlpList[$chargepoint]}"
        ;;
      *)
        fail "invalid command: [$cmd]"
        ;;
    esac
  fi
}

prepareExtopenwb() {
  local chargepoint=$1  #0..7
  local phase=$2        #1, 3
  local loadmgmt=$3
  local active=$4       #u1p3plpxaktiv 0,1
  exportBaseParams $chargepoint "extopenwb" $loadmgmt $active
  local chargepIpValue=${chargeIpValList[$chargepoint]}
  
  if [ $cmd = "1" ] || [ $cmd = "3" ]
  then
    writeExpectedRamDisk "u1p3pstat" "$cmd"
  fi
  
  if [ $chargepoint -gt 0 ] && [ $loadmgmt -eq 0 ]
  then
    : #do nothing
  else
      case $cmd in
      "1"|"3")
        writeExpectedCall "mosquitto_pub -r -t openWB/set/isss/U1p3p -h $chargepIpValue -m $cmd"
        ;;
      "stop")
        writeExpectedCall "mosquitto_pub -r -t openWB/set/isss/Current -h $chargepIpValue -m 0"
        echo "${llsollValList[$chargepoint]}" > ramdisk/${llsollList[$chargepoint]}
        writeExpectedRamDisk "tmpllsoll" "${llsollValList[$chargepoint]}"
        ;;
      "start")
        writeExpectedCall "mosquitto_pub -r -t openWB/set/isss/Current -h $chargepIpValue -m ${llsollValList[$chargepoint]}"
        echo "${llsollValList[$chargepoint]}" > ramdisk/${tmpllsollList[$chargepoint]}
        ;;
      "startslow")
        writeExpectedCall "mosquitto_pub -r -t openWB/set/isss/Current -h $chargepIpValue -m ${minimalapv}"
        ;;
      *)
        fail "invalid command: [$cmd]"
        ;;
    esac
  fi
}

testModbusevse1p3p() {
  for chargepoint in {0..7}
  do
    for cmd in "1" "3" "stop" "start" "startslow"
    do
      for active in 0 1
      do
        for loadmgmt in 0 1
        do
          setUp
          #echo "modbus cp:$(($chargepoint+1)) cmd:$cmd loadmgmt:$loadmgmt active:$active"
          prepareModbusEvse $chargepoint $cmd $loadmgmt $active
          ${scriptDir}u1p3pcheck.sh $cmd
          checkCalls
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
    for cmd in "1" "3" "stop" "start" "startslow"
    do
      for active in 0 1
      do
        for loadmgmt in 0 1
        do
          setUp
          #echo "ipevse cp:$(($chargepoint+1)) phase:$phase loadmgmt:$loadmgmt active:$active"
          prepareIpEvse $chargepoint $cmd $loadmgmt $active
          ${scriptDir}u1p3pcheck.sh $cmd
          checkCalls
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
    for cmd in "1" "3" "stop" "start" "startslow"
    do
      for active in 0 1
      do
        for loadmgmt in 0 1
        do
          setUp
          #echo "extopenwb cp:$(($chargepoint+1)) cmd:$cmd loadmgmt:$loadmgmt active:$active"
          prepareExtopenwb $chargepoint $cmd $loadmgmt $active
          ${scriptDir}u1p3pcheck.sh $cmd
          checkCalls
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
      for cmd in "1" "3" "stop" "start" "startslow"
      do
        for loadmgmt in 0 1
        do
          setUp
          prepareModbusEvse $chargepoint $cmd $loadmgmt $active
          prepareExtopenwb $(($chargepoint+1)) $cmd $loadmgmt $active
          prepareIpEvse $(($chargepoint+2)) $cmd $loadmgmt $active
          ${scriptDir}u1p3pcheck.sh $cmd
          checkCalls
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
  local cnt=$(<${callCntFile})
  echo "openwbDebugLog $@" > ${testDir}call_${cnt}.tst
  cnt=$(($cnt+1))
  echo "$cnt" > $callCntFile
}

# overwrite
sudo() {
  local cnt=$(<${callCntFile})
  echo "sudo $@" > ${testDir}call_${cnt}.tst
  cnt=$(($cnt+1))
  echo "$cnt" > $callCntFile
}

# overwrite
mosquitto_pub() {
  local cnt=$(<${callCntFile})
  echo "mosquitto_pub $@" > ${testDir}call_${cnt}.tst
  cnt=$(($cnt+1))
  echo "$cnt" > $callCntFile
}

# overwrite
set-current.sh() {
  local cnt=$(<${callCntFile})
  echo "runs/set-current.sh $@" > ${testDir}call_${cnt}.tst
  cnt=$(($cnt+1))
  echo "$cnt" > $callCntFile
}

setUp() {
  #echo "SetUp"
  export u1p3ppause
  export minimalapv
  export -f openwbDebugLog
  export -f sudo
  export -f mosquitto_pub

  if [ ! -d $testDir ]
  then
    mkdir $testDir
  fi
  touch $expectedCallCntFile
  echo "0" > $expectedCallCntFile

  export testDir
  export callCntFile
  echo "0" > $callCntFile
  if [ ! -d "ramdisk" ]
  then
    mkdir ramdisk
  fi
}

tearDown() {
  #echo "TearDown"
  rm -rf $testDir

  if [ -d "ramdisk" ]
  then
   rm -rf ramdisk
  :
  fi
  #unset openwbDebugLog
  #unset sudo
}


#oneTimeSetUp() {
  # echo "OneTimeSetUp"
  # go from test folder into parent folder
  # this has the drawback that all tests have to be listed
  # in the suite manually and are not detected automatically
#  cd ..
#  mkdir $testDir
#}

#oneTimeTearDown() {
  # echo "OneTimeTearDown"
  # switch back to test foler
#  cd test
#  rm -rf $testDir
#}

testSimple() {
  local chargepoint=2
  local active=0
  local cmd="start"
  local loadmgmt=1
  echo "extopenwb cp:$(($chargepoint+1)) cmd:$cmd loadmgmt:$loadmgmt active:$active"
  #prepareModbusEvse $chargepoint $cmd $loadmgmt $active
  prepareExtopenwb $chargepoint $cmd $loadmgmt $active
  ${scriptDir}u1p3pcheck.sh $cmd
  checkCalls
}

# uncomment to run a dedicated set of tests or a single test
suite() {
  #suite_addTest testModbusevse1p3p
  #suite_addTest testIpEvse1p3p
  #suite_addTest testExtopenwb1p3p
  suite_addTest testCombined1p3p
  #suite_addTest testSimple
}

# run unit tests using shunit2
source shunit2
