require 'helper'

describe Twitter::Client do
  %w(json xml).each do |format|
    context ".new(:format => '#{format}')" do
      before do
        @client = Twitter::Client.new(:format => format)
      end

      describe ".report_spam" do

        before do
          stub_post("1/report_spam.#{format}").
            with(:body => {:screen_name => "sferik"}).
            to_return(:body => fixture("sferik.#{format}"), :headers => {:content_type => "application/#{format}; charset=utf-8"})
        end

        it "should get the correct resource" do
          @client.report_spam("sferik")
          a_post("1/report_spam.#{format}").
            with(:body => {:screen_name => "sferik"}).
            should have_been_made
        end

        it "should return the specified user" do
          user = @client.report_spam("sferik")
          user.name.should == "Erik Michaels-Ober"
        end
      end
    end
  end
end
