class PayoutConfirmation < ActiveRecord::Base
  include UuidPrimaryKey

  CONFIRMATION_TYPES = { 1 => 'Bank', 2 => 'Payout Info', 3 => 'Payout Threshold' }


end
