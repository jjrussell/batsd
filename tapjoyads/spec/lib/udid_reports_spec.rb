require 'spec_helper'

describe UdidReports do
  before :each do
    UdidReports.const_set('NUM_REWARD_DOMAINS', 1) # fake global const as module const for test

    UdidReports.stub(:cache_available_months).and_return([1,2,3])
    bucket = FakeBucket.new
    S3.stub(:bucket).with(BucketNames::UDID_REPORTS).and_return(bucket)
    s3object = bucket.objects["udid_report/test_report.csv"]
    f = Tempfile.new("udid-report")
    @report_filepath = f.path
    f.unlink
    @report_file = File.new(@report_filepath, "w")
    File.stub(:open).and_return(@report_file)
    @offer_id = 0
    @date_str = "1999-03-01"
    @good_apps_data = {"1" => 101, "2" => 202}
    @bad_apps_data = "{just plain bad data}"
    @device = Device.new(:key => UUIDTools::UUID.random_create.to_s, :consistent => true)
    reward = Reward.new(:key => UUIDTools::UUID.random_create.to_s, :consistent => true)
    reward.udid = @device.id
    UdidReports.const_set("REWARD", reward)
    class Reward
      def self.test_select(options={})
        yield(UdidReports::REWARD)
      end

      class << self
        alias_method :original_select, :select
        alias_method :select, :test_select
      end
    end
  end

  after :each do
    UdidReports.send(:remove_const, :NUM_REWARD_DOMAINS)
    UdidReports.send(:remove_const, :REWARD)
    class Reward
      class << self
        alias_method :select, :original_select
      end
    end
    File.unlink(@report_file.path)
  end

  describe "#generate_report" do
    it "should generate UDID report" do
      @device.apps = @good_apps_data
      @device.save
      UdidReports.generate_report(@offer_id, @date_str)
      buf = File.read(@report_filepath)
      buf.match(/,/).should_not be_nil
    end

    it "should generate UDID report even if device has bad data" do
      @device.apps = @bad_apps_data
      @device.save
      expect{UdidReports.generate_report(@offer_id, @date_str)}.to_not raise_error
      buf = File.read(@report_filepath)
      buf.length.should == 0
    end
  end
end
