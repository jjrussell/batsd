require 'test_helper'

class EmailSignupTest < ActiveSupport::TestCase
  
  context "An EmailSignup" do
    setup do
     @email_signup = Factory(:email_signup)
     @email_address = @email_signup.email_address
    end
    
    should "be correctly found when searched by dynamic finder attribute methods" do
      assert_equal @email_signup, EmailSignup.find_by_email_address(@email_address, :consistent => true)
      assert_equal @email_signup, EmailSignup.find_all_by_email_address(@email_address, :consistent => true).first
    end
    
    should "raise errors when dynamic finder attributes are not matched" do
      assert_raise NoMethodError do
        EmailSignup.find_by_nonexistent_attribute("hello")
      end
      
      assert_raise NoMethodError do
        EmailSignup.do_something_that_doesnt_exist("hello")
      end
    end
  end
  
  context "Multiple new EmailSignups" do
    setup do
      @count = EmailSignup.count(:consistent => true)
      @num = 5
      @num.times { Factory(:email_signup) }
    end
    
    should "be counted correctly" do
      assert_equal @count + @num, EmailSignup.count(:consistent => true)
    end
  end
  
end
