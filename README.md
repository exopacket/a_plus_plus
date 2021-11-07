# a_plus_plus

Custom MacBook login screen and pam modules using multipeer connectivity and usb hardware checks with iOS app for sign in.

//TODO:

//   shutdown, reboot, and sleep from login screen

//   Actual Login Screen implementation (other than pam module for sudo, su, etc)

//   Screensaver implementation

//   Better documentation

//   Install script

The files are not commented very well, so I apologize for that.

All .so files for pam development on macos are for arm64.

# features

- uuid ("hardware") check for iPhone; must be plugged in to authenticate successfully. (optional)
- random pin that is encrypted & used for key generation on one device and decrypted on another using multipeer.
- 10 second delay to prevent unwanted authentication (ex: a script) and to notify the user of a login attempt.
- app written in swift to control authentication, as well as full screen login screen that cannot be exited until delay is complete.

# known vulnerabilities (unwanted features)

- Application could be called from within a loop, causing the login screen and authentication system to be called repeatedly.
- Unwanted calls to the pam module has no mechanism for prevention.
- No overall logging system within the pam module.
