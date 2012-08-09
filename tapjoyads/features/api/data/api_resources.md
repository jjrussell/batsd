# Let models be served over an API

Author: Inderpreet Singh

## Description
We should let models be rendered via a data api.

## Test plan

### Test 1
1. Get requests to any api url should be rejected
2. Post requests without the API token are rejected.


### Test 2
1. All responses much have a ```success``` flag. This should always be set, if the server got the request.
2. ```errors``` should be set if the request had errors.

### Test 3
1. Looking up the API, the safe attributes should be present in the data.
2. It should not have any other attributes other than the ones marked safe.

### Test 4
1. Anything marked with a sync flag, sets those attributes on the object.
2. The object is saved only if its an existing object, or create_new flag is set to true.
3. It should return the changed object.
