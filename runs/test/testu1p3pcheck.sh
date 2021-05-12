#!/bin/bash
# requirements: install shunit2:
# sudo apt-get install shunit2

#evseconTypes=("modbusevse","ipevse","extopenwb")
#evseconlpxTypes=("ipevse","extopenwb")

#template
#  export u1p3ppause="2"
#  export evsecon=${evseconTypes[0]}
#  export evsecons1=${evseconlpxTypes[0]}
#  export evsecons2=${evseconlpxTypes[0]}
#  export evseconlp4=${evseconlpxTypes[0]}
#  export evseconlp5=${evseconlpxTypes[0]}
#  export evseconlp6=${evseconlpxTypes[0]}
#  export evseconlp7=${evseconlpxTypes[0]}
#  export evseconlp8=${evseconlpxTypes[0]}
#  export evseiplp1="1.1.1.1"
#  export evseiplp2="2.2.2.2"
#  export evseiplp3="3.3.3.3"
#  export evseiplp4="4.4.4.4"
#  export evseiplp5="5.5.5.5"
#  export evseiplp6="6.6.6.6"
#  export evseiplp7="7.7.7.7"
#  export evseiplp8="8.8.8.8"
#  export u1p3plp2id="lp2id"
#  export u1p3plp3id="lp3id"
#  export u1p3plp4id="lp4id"
#  export u1p3plp5id="lp5id"
#  export u1p3plp6id="lp6id"
#  export u1p3plp7id="lp7id"
#  export u1p3plp8id="lp8id"
#  export chargep1ip="11.11.11.11"
#  export chargep2ip="22.22.22.22"
#  export chargep3ip="33.33.33.33"
#  export chargep4ip="44.44.44.44"
#  export chargep5ip="55.55.55.55"
#  export chargep6ip="66.66.66.66"
#  export chargep7ip="77.77.77.77"
#  export chargep8ip="88.88.88.88"
#  export u1p3plp2aktiv="1"
#  export u1p3plp3aktiv="1"
#  export u1p3plp4aktiv="1"
#  export u1p3plp5aktiv="1"
#  export u1p3plp6aktiv="1"
#  export u1p3plp7aktiv="1"
#  export u1p3plp8aktiv="1"

evseConList=("evsecon" "evsecons1" "evsecons2" "evseconLp4" "evseconlp5" "evseconlp6" "evseconlp7" "evseconlp8")
evseipList=("evseiplp1" "evseiplp2" "evseiplp3" "evseiplp4" "evseiplp5" "evseiplp6" "evseiplp7" "evseiplp8")
evseipValList=("1.1.1.1" "2.2.2.2" "3.3.3.3" "4.4.4.4" "5.5.5.5" "6.6.6.6" "7.7.7.7" "8.8.8.8")
u1p3plpIdList=("u1p3plp2id" "u1p3plp2id" "u1p3plp3id" "u1p3plp4id" "u1p3plp5id" "u1p3plp6id" "u1p3plp7id" "u1p3plp8id")
u1p3plpIdValList=("id1" "id2" "id3" "id4" "id5" "id6" "id7" "id8")
chargepIpList=("chargep1ip" "chargep2ip" "chargep3ip" "chargep4ip" "chargep5ip" "chargep6ip" "chargep7ip" "chargep8ip")
chargeIpValList=("11.11.11.11" "22.22.22.22" "33.33.33.33" "44.44.44.44" "55.55.55.55" "66.66.66.66" "77.77.77.77" "88.88.88.88")
u1p3plpAktivList=("" "u1p3plp2aktiv" "u1p3plp3aktiv" "u1p3plp4aktiv" "u1p3plp5aktiv" "u1p3plp6aktiv" "u1p3plp7aktiv" "u1p3plp8aktiv")

#',' as separator ... to be later able to split the string into individual arguments
#     chargepoint,chargetype,phases,expectedOpenWbDebugLog,           expectedSudoContent           expectedRamDisku1p3pstatContent
CHARGE_POINT=0
CHARGE_TYPE=1
PHASE=2
EXP_OPENWB_DEBUG_LOG=3
EXP_SUDO=4
EXP_MOSQUITTO=5
EXP_RAMD_U1P3PSTAT=6
testList[0]="0,modbusevse,1,MAIN 0 Pause nach Umschaltung: 2s,python runs/trigopen.py -d 2,,1"
testList[1]="0,modbusevse,3,MAIN 0 Pause nach Umschaltung: 2s,python runs/trigclose.py -d 2,,3"
testList[2]="0,ipevse,1,,python runs/u1p3premote.py -a 1.1.1.1 -i id1 -p 1 -d 2,,1"
testList[3]="0,ipevse,3,,python runs/u1p3premote.py -a 1.1.1.1 -i id1 -p 3 -d 2,,3"
testList[4]="0,extopenwb,1,,,-r -t openWB/set/isss/U1p3p -h 11.11.11.11 -m 1,1"


#testlp1Modbusevse1p() {
#  export evsecon="modbusevse"
#  ../u1p3pcheck.sh 1
#  callContent=$(<openwbDebugLog.tst)
#  assertEquals "MAIN 0 Pause nach Umschaltung: 2s" "$callContent"
#  callContent=$(<sudo.tst)
#  assertEquals "python runs/trigopen.py -d 2" "$callContent"
#  callContent=$(<ramdisk/u1p3pstat)
#  assertEquals "1" "$callContent"
#}

#testlp1Modbusevse3p() {
#  export evsecon="modbusevse"
#  ../u1p3pcheck.sh 3
#  callContent=$(<openwbDebugLog.tst)
#  assertEquals "MAIN 0 Pause nach Umschaltung: 2s" "$callContent"
#  callContent=$(<sudo.tst)
#  assertEquals "python runs/trigclose.py -d 2" "$callContent"
#  callContent=$(<ramdisk/u1p3pstat)
#  assertEquals "3" "$callContent"
#}

check() {
  testNumber=$1 #0..n
  testParams=${testList[$testNumber]}
  #split testParams string separated by "," into array of strings
  IFS=',' read -r -a params <<< "$testParams"
  chargepoint=${params[$CHARGE_POINT]}
  chargetype=${params[$CHARGE_TYPE]}
  evseconNumber=${evseConList[$chargepoint]}
  export $evseconNumber="$chargetype"
  evseIp=${evseipList[$chargepoint]}
  evseIpValue=${evseipValList[$chargepoint]}
  export $evseIp="$evseIpValue"
  u1p3pId=${u1p3plpIdList[$chargepoint]}
  u1p3pIdValue=${u1p3plpIdValList[$chargepoint]}
  export $u1p3pId="$u1p3pIdValue"
  chargepIp=${chargepIpList[$chargepoint]}
  chargepIpValue=${chargeIpValList[$chargepoint]}
  export $chargepIp="$chargepIpValue"
  switchPhase=${params[$PHASE]}
  ../u1p3pcheck.sh $switchPhase
  callContent=$(<openwbDebugLog.tst)
  expOpenWbDebugLog=${params[$EXP_OPENWB_DEBUG_LOG]}
  assertEquals "$expOpenWbDebugLog" "$callContent"
  callContent=$(<sudo.tst)
  expSudo=${params[$EXP_SUDO]}
  assertEquals "$expSudo" "$callContent"
  callContent=$(<mosquitto_pub.tst)
  expMosquitto=${params[$EXP_MOSQUITTO]}
  assertEquals "$expMosquitto" "$callContent"
  callContent=$(<ramdisk/u1p3pstat)
  expRamDU1p3pStat=${params[$EXP_RAMD_U1P3PSTAT]}
  assertEquals "$expRamDU1p3pStat" "$callContent"
}

testlp1Modbusevse1p() { check 0; }
testlp1Modbusevse3p() { check 1; }
testlp1Ipevse1p() { check 2; }
testlp1Ipevse1p() { check 3; }
testlp1ExtOpenWb1p() { check 4; }

# overwrite 
openwbDebugLog() {
  echo "$@" > openwbDebugLog.tst
}

# overwrite
sudo() {
 echo "$@" > sudo.tst
}

# overwrite
mosquitto_pub() {
  echo "$@" > mosquitto_pub.tst
}

setUp() {
  #echo "SetUp"
  export u1p3ppause="2"
  export -f openwbDebugLog
  export -f sudo
  export -f mosquitto_pub
  touch openwbDebugLog.tst
  touch sudo.tst
  touch mosquitto_pub.tst
  mkdir ramdisk
  touch ramdisk/u1p3pstat
}

tearDown() {
  #echo "TearDown"
  rm *.tst
  rm -rf ramdisk
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
#suite() {
  #suite_addTest testlp1Modbusevse3p
  #suite_addTest testlp1Modbusevse1p
#  suite_addTest testlp1ExtOpenWb1p
#}

# run unit tests using shunit2
source shunit2
