class EarningsAdjustment < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :partner

  validates_presence_of :partner
  validates_presence_of :notes
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false

  after_create :update_balance

  named_scope :created_between, lambda { |start_time, end_time| { :conditions => [ "created_at >= ? AND created_at < ?", start_time, end_time ] } }

  def <=> other
    created_at <=> other.created_at
  end

private

  def update_balance
    return true if amount == 0
    Partner.connection.execute("UPDATE partners SET pending_earnings = (pending_earnings + #{amount}), next_payout_amount = (next_payout_amount + #{amount}) WHERE id = '#{partner_id}'")
  end

end
