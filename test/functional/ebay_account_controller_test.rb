require 'test_helper'

class EbayAccountControllerTest < ActionController::TestCase
  test "index should redirect to ebay" do
    get :index
    
    assert_response :redirect
  end
end
