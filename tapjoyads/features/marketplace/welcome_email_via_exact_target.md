# Tapjoy.com Welcome Emails Sent via ExactTarget

Author: Brian Stebar


## Feature Description
When a new user signs up for Tapjoy.com, they will be sent an email confirmation.  This confirmation email will be triggered by a SOAP API request to ExactTarget.

## Technical Flow
When a user submits the signup form, a message is placed on the `SendWelcomeEmails` SQS queue.  The job `queue_send_welcome_emails_controller` consumes the queue message and sends a SOAP API request to ExactTarget containing only the dynamic data to be included in the email.  Since the template for the welcome email lives within ExactTarget, the generation and sending of the email takes place outside Tapjoy's system.


## Test Plan

### Prerequisites
The `dev_SendWelcomeEmails` queue is a shared resource in Tapjoy's development environment.  While not required, it's helpful to flush the queue of stale messages before beginning the test plan.  Also, the email account to be used to receive the test email must not have been previously used during registration.  It is recommended that this test be performed using a freshly-reset database to avoid this issue.

* Run `Sqs.delete_messages(QueueNames::SEND_WELCOME_EMAILS, /[a-z]+/)` within the Rails console to clear the welcome emails SQS queue.
  * Note: This function runs indefinitely and dumps the contents of each message it deletes into the console.  When it ceases outputting the contents, the SQS cache has been cleared.  To verify this, navigate to `http://localhost:8080/dashboard/tools/sqs_lengths`.
* Run `rake db:sync` from a terminal to reset your local database and remove all previous gamer registrations.


### Test: Trigger the welcome email

1. Navigate to the homepage at `http://localhost:8080`.
2. Click 'Sign Up'.
3. Fill out the form using your email address and dummy values for the rest of the fields, then submit the form.
  * If you see the 'Welcome to Tapjoy!' message, then the registration was successful.
4. Navigate to `http://localhost:8080/dashboard/tools/sqs_lengths` to confirm that the `SendWelcomeEmails` queue now has a message queued.
  * If more than one message has been queued, it's likely that another developer has also registered a dummy user.  This is of no concern to this test.
5. Find the `dev_SendWelcomeEmails` row and click the corresponding 'Run Once' link.
  * If presented with an authentication challenge, refer to `tapjoyads/app/helpers/authentication_helper.rb` to find credentials for the user `internal`.
  * *Note*: If other additional SQS messages are present in the `dev_SendWelcomeEmails` queue, they will likely cause your app to stack trace.  However, this is of little concern.  Since the 'Visibility Timeout' setting for this queue is 30 seconds, messages that are not successfully processed will be 'hidden' for 30 seconds.  In other words, continue refreshing the page until you get an 'ok' message.
6. Check your email for the welcome email.
  * *Note*: Due to ExactTarget's queued processing model, it can take up to 60 seconds for the email to arrive.
