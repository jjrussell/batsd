class EnableOfferRequest < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :offer
  belongs_to :requested_by, :class_name => 'User'
  belongs_to :assigned_to, :class_name => 'User'
  validates_presence_of :offer
  validates_presence_of :requested_by
  validates_numericality_of :status, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 3
  validates_each :assigned_to do |record, attr, user|
    unless user.nil? || user.is_one_of?([:account_mgr])
      record.errors.add attr, 'should be an account manager'
    end
    if user && record.assigned_to_id_was && record.assigned_to_id_was != user.id
      record.errors.add attr, 'is already assigned to another user'
    end
  end
  validates_each :offer do |record, attr, offer|
    if record.new_record?
      unless (offer.enable_offer_requests.map(&:status) & [STATUS_UNASSIGNED, STATUS_ASSIGNED]).empty?
        record.errors.add attr, 'already has a previous request in queue'
      end
    end
  end
  validates_each :status do |record, attr, status|
    if record.offer.hidden? && status == STATUS_APPROVED
      record.errors.add attr, 'cannot be approved when associated app has been archived'
    end
  end

  STATUS_UNASSIGNED = 0
  STATUS_ASSIGNED = 1
  STATUS_APPROVED = 2
  STATUS_REJECTED = 3

  scope :unassigned, :conditions => { :status => STATUS_UNASSIGNED },
    :order => 'created_at'
  scope :for, lambda { |user| {
    :conditions => { :status => STATUS_ASSIGNED, :assigned_to_id => user.id },
    :order => 'created_at'
  } }
  scope :not_for, lambda { |user| {
    :conditions => "status = '#{STATUS_ASSIGNED}' and assigned_to_id != '#{user.id}'",
    :order => 'created_at'
  } }
  scope :pending, :conditions => [ "status = ? OR status = ?", STATUS_UNASSIGNED, STATUS_ASSIGNED ],
    :order => 'created_at'

  def assign_to(user)
    self.assigned_to = user
    self.status = user.nil? ? STATUS_UNASSIGNED : STATUS_ASSIGNED
    save
  end

  def unassign
    assign_to(nil)
  end

  def approve!(approve=true)
    self.status = approve ? STATUS_APPROVED: STATUS_REJECTED
    save!
  end

  def status_text
    case status
    when STATUS_UNASSIGNED
      'unassigned'
    when STATUS_ASSIGNED
      'assigned'
    when STATUS_APPROVED
      'approved'
    when STATUS_REJECTED
      'rejected'
    end
  end
end
