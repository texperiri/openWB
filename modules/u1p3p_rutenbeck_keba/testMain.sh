#!/bin/bash
# requirements: install shunit2:
# sudo apt-get install shunit2

# valid commands: 1 and 3
testInvalidCommand() {
  for cmd in -3 -2 -1 0 2 4 5 6 7 8 9 10 11 12
  do
    #param1: cmd, param2: chargepoint
    ./main.sh $cmd 1
    #exit 1: invalid 1st input parameter
    assertEquals 1 $?
  done
}

# valid chargepoints 1-8
testInvalidChargepointCmd1() {
  for chargepoint in -3 -2 -1 0 9 10 11 12 13 14
  do
    #param1: cmd, param2: chargepoint
    ./main.sh 1 $chargepoint
    #exit 2: invalid 2nd input parameter
    assertEquals 2 $?
  done
}

testInvalidChargepointCmd3() {
  for chargepoint in -3 -2 -1 0 9 10 11 12 13 14
  do
    #param1: cmd, param2: chargepoint
    ./main.sh 3 $chargepoint
    #exit 2: invalid 2nd input parameter
    assertEquals 2 $?
  done
}

#ip address invalid
testInvalidIpConfig1() {
  export chargep1ip="1234"
  ./main.sh 1 1
  assertEquals 4 $?
}

# another invalid ip address
testInvalidIpConfig2() {
  export chargep1ip="1.2.3"
  ./main.sh 1 1
  assertEquals 4 $?
}

# ip config is empty string
testEmptyIpConfig() {
  export chargep1ip=""
  ./main.sh 1 1
  assertEquals 3 $?
}

#ip config variable not defined
testEmptyIpConfig2() {
  ./main.sh 1 1
  assertEquals 3 $?
}

#ip configured with "none" as content
testNoneIpConfig() {
  export chargep1ip="none"
  ./main.sh 1 1
  assertEquals 3 $?
}

testSwitchTo1PhaseOk() {
  export chargep1ip="1.1.1.1"
  export chargep2ip="2.2.2.2"
  export chargep3ip="3.3.3.3"
  export chargep4ip="4.4.4.4"
  export chargep5ip="5.5.5.5"
  export chargep6ip="6.6.6.6"
  export chargep7ip="7.7.7.7"
  export chargep8ip="8.8.8.8"
  export -f socat

  # test switch for every chargepoint
  for chargepoint in {1..8}
  do
    echo 0 > socatCallCnt.tst
    ./main.sh 1 $chargepoint
    ip_var="chargep${chargepoint}ip"
    ipAddress=${!ip_var}
    #expected calls
    expectedParams="- UDP-DATAGRAM:${ipAddress}:30303"
    #1: switch off release relais
    callContent=$(<call0.tst)
    assertEquals "OUT4 0" "$callContent"
    callParams=$(<call0.params.tst)
    assertEquals "$expectedParams" "$callParams"
    #2: switch to 1 phase => switch off out2 relais
    callContent=$(<call1.tst)
    assertEquals "OUT2 0" "$callContent"
    callParams=$(<call1.params.tst)
    assertEquals "$expectedParams" "$callParams"
    #3: switch on release relais
    callContent=$(<call2.tst)
    assertEquals "OUT4 1" "$callContent"
    callParams=$(<call2.params.tst)
    assertEquals "$expectedParams" "$callParams"
  done
}

testSwitchTo3PhasesOk() {
  export chargep1ip="1.1.1.1"
  export chargep2ip="2.2.2.2"
  export chargep3ip="3.3.3.3"
  export chargep4ip="4.4.4.4"
  export chargep5ip="5.5.5.5"
  export chargep6ip="6.6.6.6"
  export chargep7ip="7.7.7.7"
  export chargep8ip="8.8.8.8"
  export -f socat

  # test switch for every chargepoint
  for chargepoint in {1..8}
  do
    #reset call counter with every loop
    echo 0 > socatCallCnt.tst
    ./main.sh 3 $chargepoint
    ip_var="chargep${chargepoint}ip"
    ipAddress=${!ip_var}
    #expected calls
    expectedParams="- UDP-DATAGRAM:${ipAddress}:30303"
    #1: switch off release relais
    callContent=$(<call0.tst)
    assertEquals "OUT4 0" "$callContent"
    callParams=$(<call0.params.tst)
    assertEquals "$expectedParams" "$callParams"
    #2: switch to 1 phase => switch on out2 relais
    callContent=$(<call1.tst)
    assertEquals "OUT2 1" "$callContent"
    callParams=$(<call1.params.tst)
    assertEquals "$expectedParams" "$callParams"
    #3: switch on release relais
    callContent=$(<call2.tst)
    assertEquals "OUT4 1" "$callContent"
    callParams=$(<call2.params.tst)
    assertEquals "$expectedParams" "$callParams"
  done

}

###### mock function ######
# about mocks: https://advancedweb.hu/how-to-mock-in-bash-tests/
# also: https://opensource.com/article/19/2/testing-bash-bats#stubbing-test-input-and-mocking-external-calls
# ... best? https://github.com/zofrex/bourne-shell-unit-testing

# overwrites socat
socat() {
  # read piped input
  read pipedInput
  pipedInput_elements=($pipedInput)
  echo "${pipedInput_elements[0]} =${pipedInput_elements[1]}"
  # store input parameters and pipe input for test assertion
  socatCallCnt=$(<socatCallCnt.tst)
  echo "$1 $2" > call${socatCallCnt}.params.tst
  echo $pipedInput > call${socatCallCnt}.tst
  socatCallCnt=$((socatCallCnt+1))
  echo $socatCallCnt > socatCallCnt.tst
}

oneTimeSetUp() {
#  socatCallCnt=0
  echo "OneTimeSetUp"
}

oneTimeTearDown() {
  rm *.tst
  echo "OneTimeTearDown"
}


# uncomment to run a dedicated set of tests or a single test
#suite() {
#  suite_addTest testSwitchTo1PhaseOk
#}

# run unit tests using shunit2
source shunit2
