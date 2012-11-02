class ConsoleSecurity::Authentication < ActiveRecord::Base
  self.table_name_prefix = 'console_'

  include UuidPrimaryKey
  belongs_to :user

  attr_accessible :provider, :uid, :info
  validates :provider, :presence => true
  validates :uid, :presence => true

  def self.for_auth_hash(auth_hash)
    auth = where(:provider => auth_hash[:provider], :uid => auth_hash[:uid]).first_or_initialize
    auth.info = auth_hash[:info]
    unless auth.user.present?
      auth.user = User.where(:email => auth.info['email']).first
    end
    auth.save!
    auth
  end
end
