# Download App screenshots from the corresponding App Store.

Author: Inderpreet Singh

## Description
App stores have screenshots of the Apps. This is something that we want to store and capture. The raw images need to be saved somewhere in S3.
The images are stored in app-screenshots buckets on S3, and the list of images are stored on the Apps primary metadata.

## Test Plan

### Test 1: Download images

1. Invoke app_metadata.update_from_store.
2. This must be done for Google Play store, Apple itunes and Windows App store.
3. Make sure this downloads the corresponding screenshots over the network. For Apple, ensure the screenshots include iPad screenshots.
4. These must be saved to S3. Old screenshots should have been deleted.
5. A non code change is to make sure the bucket is configured for CDN.

### Test 2: App store down
1. All of the above steps, except, we should not create empty files or anything.

## Ops

Ensure that the bucket is CDNed. This will be really critical for performance.
