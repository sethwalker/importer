require 'test_helper'

class DashboardControllerTest < ActionController::TestCase
  test "index displays page" do
    get :index
    
    assert_response :ok
    assert_template 'index'
  end
end
