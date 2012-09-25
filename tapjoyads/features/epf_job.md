# EPF Job

Author: Daniel Lee

## Description
This job will be responsible for the download and extraction of the database files we need via Apple's EPF servers. After download and extract, the archives we need will be uploaded to S3 for processing in Hurricane.

Currently, they serve 4 archives on a weekly full, and daily incremental basis.
As of now, this downloader is only downloading from the full archive. Eventually it will need to be built out to handle the incrementals, as well as keep track of our EPF bucket on s3, making sure that all the appropriate incrementals are available should we need to rebuild the database from scratch on any given date.

## Testing
TODO: create dummy files to test with
Running `AppleEPF.download_and_extract('http://s3.amazonaws.com/dev_apple-epf/test/match20120920.tbz', ['match20120920/artist_match'], credentials = false)` should result in the file artist_match appearing inside tmp/epf/match20120920 folder. Credentials are disabled here because I rehosted the file on S3, and it errors out if erroneous credentials are provided. Verify that only the artist_match file appears. There should be no other file.
Running `AppleEPF.upload_files_in_tmp_folder` should result in the file being uploaded and appearing online at http://s3.amazonaws.com/dev_apple-epf/epf/match20120920/artist_match
(To clear the file online, run `S3.bucket(BucketNames::APPLE_EPF).objects['epf/match20120920/artist_match'].delete` and verify that the url now returns an error.)

(This is all shortcutted in the `AppleEPF.test` method.)