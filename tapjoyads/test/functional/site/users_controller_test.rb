require 'test_helper'

class Site::UsersControllerTest < ActionController::TestCase

  test "verify password" do
    assert @controller.send(:verify_password, 'password', 'b4wSDMkoenbwyfcoKCGF5lV7N40=', 'rueLoTydztbyF5ntEdewAQ==')
  end
end
