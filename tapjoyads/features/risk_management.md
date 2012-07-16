# Managing Risk in the Conversion Process


Author: Norman Chan


## Description
Adding safeguards in how the system turns clicks into conversions, by aggregating the risk scores of all related entities and combining that with the results of evaluating risk checking rules to determine if a conversion should be blocked.

* Google Doc: https://docs.google.com/a/tapjoy.com/presentation/d/1HiSRuei7-jEqOtuSnT_kL_y58AQ5TbrLo7SyUFlrF-c/edit

## Test Plan

Note: The tests below depend to a degree on the persisted risk profiles of the entities involved, as well as the set of rules configured for evaluation.  Thus, tests may not perform as expected and may need to be adjusted.  The general approach to acceptance testing this feature is valid, however.

### Prerequisite

1. Choose a currency/app/partner to test with. This will be the app where the offer will be clicked on from.
2. Update partner's `enable_risk_management` flag to `true`.

### Test 1: Successful (low risk) conversion

1. Click on an offer
2. Simulate a conversion call using the click key (e.g. connect or offer_completed).  May need to manually call conversion tracking queue job.
3. Click should be successfully converted (confirm via the Tools->Device Info page)
4. Click on the click's install date to load the ConversionAttempt details page and inspect the associated risk profiles and rules matched

### Test 2: Unsuccessful (high risk score based on risk profiles) conversion

1. Click on an offer
2. Use Rails console to fetch RiskProfile objects for various entities (APP, OFFER, COUNTRY, DEVICE, IPADDR) and set the risk score offsets to 100 (maximum risk)
3. Simulate a conversion call using the click key (e.g. connect or offer_completed).  May need to manually call conversion tracking queue job.
4. Click conversion should be blocked, with message "Conversion risk is too high" (confirm via the Tools->Device Info page)
5. Click on the error message to load the ConversionAttempt details page and inspect the associated risk profiles and rules matched

### Test 3: Unsuccessful (high risk based on rule evaluation failure) conversion

1. Click on an offer
2. Use Rails console to fetch RiskProfile object for the device associated with the click
3. Create a Reward object with a high value for advertiser_amount (like -9999, current rules include one that blocks if more than $100 is processed for a single device in a 24 hour period)
4. Call `process_conversion` with the reward object to prime the device's RiskProfile
5. Simulate a conversion call using the click key (e.g. connect or offer_completed).  May need to manually call conversion tracking queue job.
6. Click conversion should be blocked, with message "Conversion risk is too high" (confirm via the Tools->Device Info page)
7. Click on the error message to load the ConversionAttempt details page and inspect the associated risk profiles and rules matched

### Test 4: Force convert a blocked conversion

1. Using either of the techniques above, generate a blocked conversion.
2. On the Tools->Device Info page, the conversion should be shown as 'Blocked' or 'Wont Reward'.  It will also have a button labeled 'Force' under the Resolve column
3. Click the Force button.  Message appears on top of the page: "Force conversion request sent. It may take some time for this request to be processed."
4. If needed, manually call conversion tracking queue job
5. Reload Device Info page to verify click is now converted
6. Click on the click's install date to load the ConversionAttempt details page and verify that the current user is indicated under the "Force converted by" field
