# Allow connect calls from devices and temporary devices

Author: Inderpreet Singh

## Description
We should be able to allow connect calls from devices we have seen earlier as well as identifiers that we can not lookup.


## Test Plan

### Test 1: When a UDID is present

1. A connect call made with the basic information (app_id and udid) should always succeed.
2. It should create/update the device corresponding to the UDID.
3. It should create a web request with the right paths that will update the stats.

### Test 2: When a mac_address is present but udid is not

1. A connect call with mac_address but no udid is made.
2. It should create/update a device who udid is the mac_address.
3. A web request must be created to update the stats.

### Test 3: When a udid and mac_address both are present

1. A connect call made with both gives precedence to UDID.
2. The device with udid will be created/updated.
3. Web request should be created.
4. Any existing device corresponding to the mac_address should be merged with the device corresponding to the UDID.

### Test 4: When only an identifier is present, and we have that identifier present in our db.

1. We try to lookup the device corresponding to the udid.
2. We note that this UDID was looked up in the web request.
3. Test 1 is continued since we now have a device.

### Test 5: When an identifier is present, but we have not seen that device.

1. A call using just an identifier will attempt to lookup the UDID.
2. If the device is not found, then it will return a new device that is marked as a temporary device.
3. If this identifier was seen in the past, the temporary device should also the apps from the last time.
4. A web request with the right paths should be created with the temporary device.
5. The temporary device is not saved, but a temporary device is persisted when we attempt to save the current device.

### Test 6: When we get a UDID, whose identifiers we have seen in connect.

1. Test 1 is carried out.
2. A message is sent to the device identifier queue to create identifiers.
3. This will find all temporary devices for its identifiers and merge them in with the device.
4. The device should have app history from its identifiers.
5. The temporary devices should have been deleted.

