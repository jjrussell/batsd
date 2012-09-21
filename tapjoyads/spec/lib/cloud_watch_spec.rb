require 'spec_helper'

describe CloudWatch do
  describe 'parse_xml_response' do
    before :each do
      @success_response = "<SuccessfulActionResponse><ResponseMetadata><RequestId>ee51e2ca-038a-11e2-9479-9fb0624b49ba</RequestId></ResponseMetadata></SuccessfulActionResponse>"
      @failure_response = "<ErrorResponse><ErrorMessage>You shouldn't have done that</ErrorMessage></ErrorResponse>"
    end

    it 'parses a successful cloudwatch xml response' do
      response = CloudWatch.parse_xml_response(@success_response)
      response['ErrorResponse'].nil?.should be_true
    end

    it 'parses a failed cloudwatch xml response' do
      response = CloudWatch.parse_xml_response(@failure_response)
      response['ErrorResponse'].nil?.should be_false
    end

    it 'does not raise if not told to on error' do
      CloudWatch.parse_xml_response(@failure_response)
      CloudWatch.parse_xml_response(@failure_response, nil)
    end

    it 'raises if told to on error' do
      lambda { CloudWatch.parse_xml_response(@failure_response, 'boom') }.should raise_exception('boom')
    end
  end
end
