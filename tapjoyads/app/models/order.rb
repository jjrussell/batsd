# == Schema Information
#
# Table name: orders
#
#  id             :string(36)      not null, primary key
#  partner_id     :string(36)      not null
#  payment_txn_id :string(36)
#  refund_txn_id  :string(36)
#  coupon_id      :string(36)
#  status         :integer(4)      default(1), not null
#  payment_method :integer(4)      not null
#  amount         :integer(4)      default(0), not null
#  created_at     :datetime
#  updated_at     :datetime
#  note           :text
#  invoice_id     :integer(4)
#  description    :string(255)
#  note_to_client :string(255)
#

class Order < ActiveRecord::Base
  include UuidPrimaryKey

  STATUS_CODES = {
    0 => 'Failed Invoice',
    1 => 'Normal',
  }

  PAYMENT_METHODS = {
    0 => 'Website',
    1 => 'Invoice',
    2 => 'Marketing Credits',
    3 => 'Transfer',
    4 => 'Recoupable Marketing Credits',
    5 => 'Bonus',
  }

  belongs_to :partner

  validates_presence_of :partner
  validates_presence_of :billing_email, :on => :create, :if => :billable?, :message => "Partner needs a billing email for invoicing"
  validates_presence_of :note, :on => :create
  validates_inclusion_of :status, :in => STATUS_CODES
  validates_inclusion_of :payment_method, :in => PAYMENT_METHODS
  validates_uniqueness_of :invoice_id, :allow_nil => true
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false

  after_create :update_balance

  delegate :billing_email, :freshbooks_client_id, :to => :partner

  scope :not_invoiced, :conditions => 'status = 0'
  scope :created_since, lambda { |date| { :conditions => [ "created_at > ?", date ] } }
  scope :created_between, lambda { |start_time, end_time| { :conditions => [ "created_at >= ? AND created_at < ?", start_time, end_time ] } }

  def <=> other
    created_at <=> other.created_at
  end

  def status_string
    STATUS_CODES[status]
  end

  def payment_method_string
    PAYMENT_METHODS[payment_method]
  end

  def is_order?;                        payment_method==0; end
  def is_invoiced?;                     payment_method==1; end
  def is_marketing_credit?;             payment_method==2; end
  def is_transfer?;                     payment_method==3; end
  def is_recoupable_marketing_credit?;  payment_method==4; end
  def is_bonus?;                        payment_method==5; end

  def create_freshbooks_invoice!
    return if invoice_id

    partner.freshbooks_client_id = FreshBooks.get_client_id(billing_email)
    partner.save! if partner.freshbooks_client_id_changed?

    if freshbooks_client_id
      self.invoice_id = FreshBooks.create_invoice(invoice_details)
      self.status = 1
    else
      self.status = 0
    end
    self.save!
  end

  def failed_invoice?
    status == 0
  end

  def billable?
    payment_method == 1
  end

  private

  def invoice_details
    {
      :invoice => {
        :client_id => freshbooks_client_id,
        :invoice_id => invoice_id,
        :notes => note_to_client,
        :lines => [
          {
            :name => 'TapjoyAdsCredit',
            :description => description,
            :unit_cost => 1,
            :quantity => amount / 100.0,
            :type => 'Item',
          },
        ],
      }
    }
  end

  def update_balance
    return true if amount == 0
    Partner.connection.execute("UPDATE partners SET balance = (balance + #{amount}) WHERE id = '#{partner_id}'")
  end

end
