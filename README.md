# UITestHelper
A bunch of utility scripts intended to address some of the common problems in iOS Unit Testing and UI Testing

## uitestrunner.sh
This script is aimed at mitigating the flakiness of UITests in iOS. In the case of UITests, it often happens that some tests might fail when the entire test suite is run, but the same tests will pass when ran in isolation.
The script re-runs the failed tests a fixed number of times until they pass.
It accepts the following arguments: 
* c: Parallel Testing Workers Count (Do not pass if parallel testing not intended)
* w: Workspace of the project
* d: Destination of the test (e.g. platform=iOS Simulator,name=iPad Pro (12.9-inch),OS=12.2)
* t: Target of the project (e.g. YourApp_UITests)
* l: Retry Limit; The number of retries that you want the program to run.
