# Detect whitelist conflicts

Author: Hwan-Joon Choi


## Description
When offer whitelist and app metadata blacklists conflict, offers don't show up in offerwalls and people get upset.

* Other Pertinent URLs: http://lmgtfy.com/?q=how+is+babby+born#


## Test Plan

### Test 1: Normal user happy path

1. Enable some offer.
2. View offer in offerwall.
3. Profit!


### Test 2: Normal user bad form

1. Enable some offer.
2. Set country targeting to US only.
3. Add US to app metadata blacklist.
4. Offer no longer in offerwall.
5. Go to statz/show for that offer and see the country field highlighted.
