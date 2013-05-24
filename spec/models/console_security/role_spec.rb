require 'spec_helper'

describe ConsoleSecurity::Role do
  it { should_not allow_mass_assignment_of :id }
  include_examples 'application_specific'

  it { should validate_presence_of :name }
  it { should have_and_belong_to_many :security_permits }
  it { should have_and_belong_to_many :security_restrictions }

  it 'should properly persist associated objects' do
    permit0 = ConsoleSecurity::SecurityPermit.new(:name => 'Permit 0')
    permit0.permissions << ConsoleSecurity::Permission.new(:action => 'read', :target => '*')
    permit0.permissions << ConsoleSecurity::Permission.new(:action => 'write', :target => 'Offer')
    permit0.save!

    restr0 = ConsoleSecurity::SecurityRestriction.new(:name => 'Restriction 0')
    restr0.permissions << ConsoleSecurity::Permission.new(:action => 'read', :target => 'Conversion#tapjoy_amount')
    restr0.save!

    role = ConsoleSecurity::Role.new(:name => 'Test Role')
    role.security_permits << permit0
    role.security_restrictions << restr0
    role.save!
  end
end
