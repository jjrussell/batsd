require 'spec_helper'

describe EmailSignup do

  context 'An EmailSignup' do
    before :each do
     @email_signup = Factory(:email_signup)
     @email_address = @email_signup.email_address
    end

    it 'is correctly found when searched by dynamic finder attribute methods' do
      EmailSignup.find_by_email_address(@email_address, :consistent => true).should == @email_signup
      EmailSignup.find_all_by_email_address(@email_address, :consistent => true).first.should == @email_signup
    end

    it 'raises errors when dynamic finder attributes are not matched' do
      expect {
        EmailSignup.find_by_nonexistent_attribute('hello')
      }.to raise_error(NoMethodError)

      expect {
        EmailSignup.do_something_that_doesnt_exist('hello')
      }.to raise_error(NoMethodError)
    end
  end

  context 'Multiple new EmailSignups' do
    before :each do
      @count = EmailSignup.count(:consistent => true)
      @num = 5
      @num.times { Factory(:email_signup) }
    end

    it 'is counted correctly' do
      EmailSignup.count(:consistent => true).should == @count + @num
    end
  end

end
