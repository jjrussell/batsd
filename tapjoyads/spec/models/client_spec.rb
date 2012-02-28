require 'spec_helper'

describe Client do
  subject { Factory(:client) }

  describe '.has_many' do
    it { should have_many(:partners) }
  end

  describe '#valid?' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end

  describe '.ordered_by_name' do
    it 'orders clients by name' do
      @client = Factory(:client, :name => 'BBB')
      @client2 = Factory(:client, :name => 'CCC')
      @client3 = Factory(:client, :name => 'AAA')
      Client.ordered_by_name.should == [ @client3, @client, @client2 ]
    end
  end

  describe '#remove_from_partners' do
    context 'before destroy' do
      before :each do
        @client = Factory(:client)
        @partner = Factory(:partner, :client => @client)
        @partner2 = Factory(:partner, :client => @client)
        @partner3 = Factory(:partner, :client => @client)
      end

      it 'removes client_id from all associated partners' do
        @client.destroy
        @partner.reload.client_id.should be_nil
        @partner2.reload.client_id.should be_nil
        @partner3.reload.client_id.should be_nil
      end
    end
  end

end
