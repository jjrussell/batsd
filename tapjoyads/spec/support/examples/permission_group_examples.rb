shared_examples 'permission_group' do
  it { should validate_presence_of :name }
  it { should allow_mass_assignment_of :name }
  it { should have_many :permissions }
end
