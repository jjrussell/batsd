require 'spec_helper'

describe Job::MasterUpdateCloudwatchAsStatsController do
  before :each do
    @sample_cpu_util = 59.92
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)
    @success_response = ActionController::TestResponse.new
    @success_response.body = "<valid_xml><req-id/></valid_xml>"
    @failure_response = ActionController::TestResponse.new
    @failure_response.body = "<ErrorResponse><ErrorMessage>You shouldn't have done that</ErrorMessage></ErrorResponse>"
  end

  describe '#index' do
    it "runs without errors" do
      @controller.stub(:newrelic_request_queue_time).and_return(5.17)
      @controller.stub(:api_cpu_utilization).and_return(@sample_cpu_util)
      CloudWatch.should_receive(:put_metric_data) do |*arg|
        arg[1].size.should == 2
        arg[1][1]['Value'].should == @sample_cpu_util
        @success_response
      end
      get(:index)
    end

    it "sets scale down metric to 100 if queuing" do
      @controller.stub(:newrelic_request_queue_time).and_return(Job::MasterUpdateCloudwatchAsStatsController::REQUEST_QUEUE_TIME_THRESHOLD)
      @controller.stub(:api_cpu_utilization).and_return(@sample_cpu_util)
      CloudWatch.should_receive(:put_metric_data) {|*arg| arg[1][1]['Value'].should == 100.0; @success_response}
      get(:index)
    end

    it "fails if newrelic call fails" do
      @controller.stub(:newrelic_request_queue_time).and_raise('badness!')
      CloudWatch.stub(:put_metric_data).and_raise('not all that bad')
      lambda { get(:index) }.should raise_exception('badness!')
    end

    it "stores request data even if cpu util data not retrievable" do
      @controller.stub(:newrelic_request_queue_time).and_return(5.17)
      @controller.stub(:api_cpu_utilization).and_raise('badness!')
      CloudWatch.should_receive(:put_metric_data) {|*arg| arg[1].size.should == 1; @success_response}
      get(:index)
    end

    it "fails if unable to store in cloudwatch" do
      @controller.stub(:newrelic_request_queue_time).and_return(5.17)
      @controller.stub(:api_cpu_utilization).and_return(@sample_cpu_util)
      CloudWatch.should_receive(:put_metric_data).exactly(3).times.and_return(@failure_response, @failure_response, @failure_response)
      lambda { get(:index) }.should raise_exception
    end
  end
end
