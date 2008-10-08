require File.dirname(__FILE__) + '/../test_helper'

class DashboardControllerTest < ActionController::TestCase
  def test_index_returns_success
    get :index
    
    assert_response :ok
    assert_template 'index'
  end
end
