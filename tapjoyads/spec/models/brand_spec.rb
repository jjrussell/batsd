require 'spec_helper'

describe Brand do
  subject { Factory(:brand) }

  it { should have_many :offers }
  it { should validate_presence_of :name }
  it { should validate_uniqueness_of(:name).case_insensitive }
end
