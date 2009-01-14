require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  test "actions redirects to login" do
    actions = [:index, :content, :summary, :errors]
    actions.each do |action|
      get action

      assert_response :unauthorized
    end
  end  
  
  test "actions should display pages if logged in" do
    set_http_auth('test', 'test')

    get :index
    assert_response :success
    assert_template 'index'
    
    get :summary, :id => imports(:word_press)
    assert_response :success
    assert_template 'summary'
    
    assert @import = assigns(:import)
    assert_equal imports(:word_press).id, @import.id
  end
end
