#!/bin/bash

# mock file for shunit2 test of openWB/runs/set-current.sh

testDir="testfiles/"
callCntFile="${testDir}callCnt.tst"

cnt=$(<${callCntFile})
echo "runs/set-current.sh $@" > ${testDir}call_${cnt}.tst
cnt=$(($cnt+1))
echo "$cnt" > $callCntFile
