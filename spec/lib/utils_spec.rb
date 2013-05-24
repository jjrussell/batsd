require 'spec_helper'

describe Utils do
  context '#ban' do
    before :each do
      @device = FactoryGirl.create(:device)
      @notes = {'date' => '10/24/12', 'reason' => 'fraud'}
      Utils.ban(@device, @notes)
    end

    it "should ban a device when passed a Device ID" do
      @device.banned.should == true
    end

    it "should save notes related to the ban" do
      @device.ban_notes[0].should == @notes
    end
  end

  context '#ban_devices' do
    before :each do
      @device1 = Device.new
      @device1.save
      device2 = Device.new
      device2.save
      click1 = Click.new
      click1.udid = @device1.id
      click1.save
      click2 = Click.new
      click2.udid = device2.id
      click2.save
      notes = {'date' => '10/24/12', 'reason' => 'fraud'}
      @click_hash = {click1.id => notes, click2.id => notes}
      @num_banned = Utils.ban_devices(@click_hash)
    end

    it "should find and ban a device when passed a Click ID" do
      Device.find(@device1.id).banned.should == true
    end

    it "should find and ban multiple devices when passed a hash of Click IDs" do
      @num_banned.should eq @click_hash.length
    end
  end

  context '#create_id_hash' do
    before :each do
      csv_string = "clickID,Reason\r7777777771,Cancelled\rd023db9b8717,Fraud"
      file = double('file')
      file.should_receive(:read).and_return(csv_string)
      @output = Utils.create_id_hash(file, nil)
    end

    it "should return a hash of Click IDs or UDIDs" do
      @output.should be_a_kind_of Hash
    end

    it "should return a hash where the keys are either Click IDs or UDIDs" do
      @output.keys[0].should match /(\w|-){10,}/
    end

    it "should return a hash where the values are hashes of ban notes" do
      @output.values[0].should be_a_kind_of Hash
    end
  end
end
