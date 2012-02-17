ActsAsApprovable.view_language = 'haml'
ActsAsApprovable::Ownership.configure do
  include UuidPrimaryKey

  def self.available_owners
    owner_class.account_managers
  end

  private
  def self.option_for_owner(owner)
    [owner.email, owner.id]
  end
end
