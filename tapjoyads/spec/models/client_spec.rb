require 'spec_helper'

describe Client do
  subject { Factory(:client) }

  # Check associations
  it { should have_many :partners }

  # Check validations
  it { should validate_presence_of :name }
  it { should validate_uniqueness_of :name }

  describe "::ordered_by_name" do
      it "orders clients by name" do
        @client = Factory(:client, :name => 'BBB')
        @client2 = Factory(:client, :name => 'CCC')
        @client3 = Factory(:client, :name => 'AAA')
        Client.ordered_by_name.should == [ @client3, @client, @client2 ]
      end
  end

  context 'A client' do
    before :each do
      @client = Factory(:client)
      @partner = Factory(:partner)
      @partner2 = Factory(:partner)
      @partner3 = Factory(:partner)
      @partner.update_attributes({ :client_id => @client.id })
      @partner2.update_attributes({ :client_id => @client.id })
      @partner3.update_attributes({ :client_id => @client.id })
    end

    it "deletes client_id from all associated partners before destroy" do
      @client.destroy
      @partner.reload
      @partner2.reload
      @partner3.reload
      @partner.client_id.should == nil
      @partner2.client_id.should == nil
      @partner3.client_id.should == nil
    end
  end

end
