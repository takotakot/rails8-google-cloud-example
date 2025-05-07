require "test_helper"

class LoggingControllerTest < ActionDispatch::IntegrationTest
  test "should get test" do
    get logging_test_url
    assert_response :success
  end
end
