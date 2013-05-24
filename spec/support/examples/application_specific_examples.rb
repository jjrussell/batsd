shared_examples 'application_specific' do
  it { should_not allow_mass_assignment_of :application }

  it 'knows the app name' do
    subject.application.should == 'tapjoyad'
  end
end
