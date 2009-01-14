require 'test_helper'

class EbayControllerTest < ActionController::TestCase
  def setup
    Import.stubs(:email_address).returns('shop@shopify.com')
  end
  
  test "index should redirect to login" do
    get :index
    
    assert_redirected_to :controller => 'login'
  end
  
  test "index should redirect to ebay account if logged in" do
    set_shopify_session
    get :index
    
    assert_redirected_to :controller => 'ebay_account'
  end
  
  test "new action display import form" do
    set_shopify_session
    set_ebay_session
    
    get :new
    
    assert_tag :tag => 'form', :attributes => {:action => '/ebay/import'}
  end
  
  test "import over html should redirect" do
    set_shopify_session
    set_ebay_session

    assert_difference "Delayed::Job.count" do
      post :import, :format => 'html'
      assert_redirected_to root_path
    end
  end
  
  test "import over js should update page with partial" do
    set_shopify_session
    set_ebay_session

    assert_difference "Delayed::Job.count" do
      post :import, :format => 'js'
    end
    
    assert_select_rjs :replace, 'confirm'
  end
end
