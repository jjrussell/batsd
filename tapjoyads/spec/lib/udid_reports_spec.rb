require 'spec_helper'


describe UdidReports do
  before :each do
    UdidReports.stub(:cache_available_months).and_return([1,2,3])
    bucket = FakeBucket.new
    S3.stub(:bucket).with(BucketNames::UDID_REPORTS).and_return(bucket)
    s3object = bucket.objects["udid_report/test_report.csv"]
    f = Tempfile.new("udid-report")
    @report_filepath = f.path
    f.unlink
    report_file = File.new(@report_filepath, "w")
    File.stub(:open).and_return(report_file)
    @offer_id = 0
    @date_str = "1999-03-01"
    @device = Device.new(:key => UUIDTools::UUID.random_create.to_s, :consistent => true)
    @reward = Reward.new(:key => UUIDTools::UUID.random_create.to_s, :consistent => true)
    @click  = Click.new(:key => UUIDTools::UUID.random_create.to_s, :consistent => true)
    @click.clicked_at = "2012-11-02 18:46:39"
    @click.save
    @reward.udid = @device.id
    @reward.click_key = @click.key
    @reward.country = 'US'
    UdidReports.const_set("REWARD", @reward)
    class Reward
      def self.test_select_all(options={})
        yield(UdidReports::REWARD)
      end

      class << self
        alias_method :original_select_all, :select_all
        alias_method :select_all, :test_select_all
      end
    end
  end

  after :each do
    UdidReports.send(:remove_const, :REWARD)
    class Reward
      class << self
        alias_method :select_all, :original_select_all
        remove_method :test_select_all
      end
    end
    File.unlink(@report_filepath)
  end

  describe "defaults" do
    it "should have accurate defaults" do
      UdidReports::UDID_REPORT_COLUMN_HEADERS.should == ["Device ID", "Created At", "Country", "MAC Address", "Clicked At"]
    end
  end

  describe "#generate_report" do
    it "should generate UDID report" do
      @device.apps = {"1" => 101, "2" => 202}
      @device.mac_address = "1234"
      @device.save
      UdidReports.generate_report(@offer_id, @date_str)
      buf = File.read(@report_filepath).chomp
      buf.split(',').length.should == 5
    end

    it 'should generate UDID report even if the device has unparsable apps data' do
      @device.save
      Device.any_instance.stub(:fix_app_json) { raise }
      expect{UdidReports.generate_report(@offer_id, @date_str)}.to_not raise_error
      buf = File.read(@report_filepath).chomp
      [4,5].should include(buf.split(',').length)
    end
  end
end
