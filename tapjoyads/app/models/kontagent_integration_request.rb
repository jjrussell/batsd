#
#   Encapsulates a partner's request for integration with Kontagent.
#
# == Schema Information
#
#  table name: kontagent_integration_requests
#
#    t.string   "subdomain"
#    t.boolean  "successful"
#    t.string   "partner_id", :limit => 36, :null => false
#    t.string   "user_id",    :limit => 36, :null => false
#    t.datetime "created_at"
#    t.datetime "updated_at"
#

class KontagentIntegrationRequest < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  attr_accessible :subdomain, :successful

  validates_format_of :subdomain, :with => /^[A-Za-z\d_]+$/

  belongs_to :partner
  belongs_to :user

  acts_as_approvable :on => :create

  def self.pending
    approvals_table = Approval.arel_table
    self.joins(:approvals).where(approvals_table[:state].eq 0).all
  end

  def after_approve(approval)
    begin
      self.provision!
    rescue StandardError => e
      Airbrake.notify(e)

      # on provisioning exception, delete all integration requests for this partner
      partner.kontagent_integration_requests.destroy_all

      # re-raise error
      raise StandardError, "Invalid response to provisioning request"
    end

    if self.successful
      KontagentMailer::approval(self.user).deliver
    end
  end

  def after_reject(rejection)
    self.save!
  end

  def successful?; self.successful end

  def no_conflicts?
    partner_exists   = KontagentHelpers.exists?(partner)
    user_exists      = KontagentHelpers.exists?(user)
    subdomain_exists = KontagentHelpers.subdomain_exists?(subdomain)
    partner_exists or user_exists or subdomain_exists ? false : true
  end

  #
  #   Kicks off the integration process. Note this is synchronous, and makes (blocking) calls to KT's remote API,
  #   so could potentially take some time if invoked by a web request.
  #
  #   Note the process could conceivably fail, so just make sure to check request.successful? afterwards to ensure
  #   KT responded appropriately to the provisioning requests.
  #
  #   Further, note that there is going to be an API made per associated application.
  #
  def provision!
    raise "Initial provisioning can only be performed once per partner" if self.partner.kontagent_enabled?
    self.successful = false
    self.save!

    provision_partner!
    provision_user!
    provision_apps!

    self.successful = true
    self.save!
    true
  end

  #
  #  Nearly identical to provisioning, except this time we are checking for
  #  existence of remote entities prior to issuing resource creation API calls.
  #
  #  (Could handle the case where a remote entity exists and the local entity
  #  doesn't know about it significantly better.)
  #
  def resync!
    raise "Resyncing can only be performed on already-integrated Partners" unless self.partner.kontagent_enabled
    self.successful = false
    self.save!

    provision_partner! unless KontagentHelpers.exists?(partner)
    provision_user! unless KontagentHelpers.exists?(user)

    self.partner.apps.each do |app|
      provision_app!(app) unless KontagentHelpers.exists?(app)
    end

    self.successful = true
    self.save!
  end

  #
  #  humanized description of integration request
  #
  def to_s
    "Kontagent integration request for partner #{self.partner.name} and user #{self.user.username} (subdomain #{self.subdomain})"
  end

  private

  def provision_partner!
    create_partner = Kontagent::Account.build!(
       :name        => partner.name,
       :subdomain   => self.subdomain,
       :account_id  => KontagentHelpers.id_for(partner)
    )
    self.partner.kontagent_enabled = true
    self.partner.kontagent_subdomain = self.subdomain
    self.partner.save!
    create_partner
  end

  def provision_user!
    create_user = KontagentHelpers.build!(self.user)
    self.user.kontagent_enabled = true
    self.user.save!
    create_user
  end

  def provision_app!(app)
    create_app = KontagentHelpers.build!(app)
    app.kontagent_enabled = true
    app.kontagent_api_key = create_app['api_key']
    app.save!
    create_app
  end

  # Can we determine somehow which apps we should integrate?
  # (One suggestion was checking the app's session data to detect activity.)
  def provision_apps!
    created_apps = []
    self.partner.apps.each { |app| created_apps << provision_app!(app) }
    created_apps
  end
end
