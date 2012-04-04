class PayoutConfirmation < ActiveRecord::Base
  include UuidPrimaryKey

  CONFIRMATION_TYPES = { 1 => 'Payout Info', 2 => 'Payout Threshold' }


end
