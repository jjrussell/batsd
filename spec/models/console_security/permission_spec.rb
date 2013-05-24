require 'spec_helper'

describe ConsoleSecurity::Permission do
  it { should_not allow_mass_assignment_of :id }
  include_examples 'application_specific'
end
