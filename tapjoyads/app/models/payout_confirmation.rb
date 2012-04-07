class PayoutConfirmation < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :partner

  def confirm
    self.confirmed = true
  end

  def unconfirm(reason=nil)
    self.confirmed = false
  end
end
