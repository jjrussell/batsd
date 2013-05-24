# Protocol Handlers for Generic Offers

Author: Van Pham


## Description
For generic offers, we want to be able to support special protocol handlers (i.e. Facebook App).  So what we can do is try to load the protocol handler, if that doesn't work, we can redirect the user to the web version of the page.

## Test Plan

### Test 1: Create offer and test
1) Create a generic offer and set the Offer Trigger to be "Protocol Handler"
2) Set it as CPC and multi-complete (so you can test multiple times if needed)
3) Boost it so it shows up on an offer wall
4) Once you see the offer, click on it using a device without the Facebook App
5) Repeat with a device with the Facebook App installed