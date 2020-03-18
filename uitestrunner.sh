#!/usr/bin/env bash

while getopts ":w:s:d:t:l:c:" opt; do
  case $opt in
    c) workers="$OPTARG"
    ;;
    w) workspace="$OPTARG"
    ;;
    s) scheme="$OPTARG"
    ;;
    d) destination="$OPTARG"
    ;;
    t) target="$OPTARG"
    ;;
    l) retry_limit="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [[ -z $workspace || -z $scheme || -z $destination || -z $target || -z $retry_limit ]]; then
  echo 'One or more arguments are undefined'
  exit 1
fi

xcodebuild_command="xcodebuild -workspace $workspace -scheme $scheme -sdk iphonesimulator -destination '$destination'  -resultBundlePath 'build' '-only-testing:$target'"

if [[ -z $workers ]]; then
  xcodebuild_command="$xcodebuild_command test"
else
  xcodebuild_command="$xcodebuild_command -parallel-testing-enabled YES -parallel-testing-worker-count $workers -quiet test"
fi

eval "$xcodebuild_command"

PLISTBUDDY="/usr/libexec/PlistBuddy -c"
PLIST="TestSummaries.plist"

base_string="xcodebuild -workspace $workspace -scheme $scheme -sdk iphonesimulator -destination '$destination'"
base_test_module=" '-only-testing:$target/"
end_quote="'"

retries=0

failure_count=0

get_inner_data() {
    j=0
    while true; do
        prefix=$1
        $PLISTBUDDY "$prefix:Subtests:$j" "$PLIST" >/dev/null 2>/dev/null
        if [ $? -ne 0 ]; then
            break
        fi
        status=$($PLISTBUDDY "$prefix:Subtests:$j:TestStatus" "$PLIST")
        if [ $status != "Success" ]; then
            failure_count=$(($failure_count + 1))
            failing_test=$($PLISTBUDDY "$prefix:Subtests:$j:TestIdentifier" "$PLIST")
            base_string=$base_string$base_test_module${failing_test%??}$end_quote
        fi
        j=$(($j + 1))
    done
}

parse_test_results() {
    i=0
    cd build
    while true; do
        prefix="Print TestableSummaries:0:Tests:0:Subtests:0:Subtests:"$i
        $PLISTBUDDY "$prefix" "$PLIST" >/dev/null 2>/dev/null
        if [ $? -ne 0 ]; then
            echo $i
            break
        fi
        get_inner_data "$prefix"
        i=$(($i + 1))
    done
    cd ../
    rm -r build
}
parse_test_results

while [ $retries -lt $retry_limit ]; do
    retries=$(($retries + 1))
    if [ $failure_count -ne 0 ]; then
        echo "Rerunning failed tests"
        command="$base_string -resultBundlePath 'build' test | xcpretty"
        eval "$command"
        base_string="xcodebuild -workspace $workspace -scheme $scheme -sdk iphonesimulator -destination '$destination'"
        failure_count=0
        parse_test_results
    else
        exit 0
    fi
done

if [ $failure_count -ne 0 ]; then
    exit 65
else
    exit 0
fi
