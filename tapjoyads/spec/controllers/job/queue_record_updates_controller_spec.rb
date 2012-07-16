require 'spec_helper'

describe Job::QueueRecordUpdatesController do
  before :each do
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)
  end

  it 'updates record as expected' do
    app = FactoryGirl.create(:app)

    new_app_name = app.name + ' Test'
    new_active_gamer_count = app.active_gamer_count + 100

    attributes = { :name => new_app_name, :active_gamer_count => new_active_gamer_count }
    message = { :class_name => 'App', :id => app.id, :attributes => attributes }
    get(:run_job, :message => Base64::encode64(Marshal.dump(message)))

    app.reload
    app.name.should == new_app_name
    app.active_gamer_count.should == new_active_gamer_count
  end
end
