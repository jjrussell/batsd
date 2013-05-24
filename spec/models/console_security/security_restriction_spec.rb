require 'spec_helper'

describe ConsoleSecurity::SecurityRestriction do
  it { should_not allow_mass_assignment_of :id }
  include_examples 'application_specific'
  include_examples 'permission_group'
  it { should have_and_belong_to_many :roles }
end
