require 'test_helper'

class WordPressControllerTest < ActionController::TestCase
  
  def setup
    ShopifyAPI::Blog.stubs(:comments_enabled?).returns(true)

    ShopifyAPI::Page.stubs(:save).returns(true)
    
    WordPressImport.any_instance.stubs(:save_data).returns(true)
    
    ShopifyAPI::Session.stubs(:create_permission_url).returns('login/finalize')
    ShopifyAPI::Session.stubs(:valid?).returns(true)
    ShopifyAPI::Session.stubs(:site).returns('localhost')
    
    set_shopify_session
    
    @import = WordPressImport.new
    @import.shop_url = 'jessetesting.myshopify.com'
    @import.content = File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press/word_press_import.xml').read
    assert @import.save
  end
     
  def test_should_redirect_to_login_if_no_session
    session['shopify'] = nil
    actions = [:index, :create, :new, :import]
    for action in actions
    get action

    assert_response :redirect
    assert_redirected_to :controller => 'login'
    end
  end   

  def test_index_should_go_to_new_if_session
    get :index

    assert_response :redirect
    assert_redirected_to :action => 'new'
  end   

  def test_new_should_display_upload_form
    get :new

    assert_response :ok
    assert_template 'new'
    assert_tag :form, :descendant => { :tag => 'input', :attributes => { :type => 'file' } }
  end
  
  def test_create_should_make_a_new_import_job
    assert_difference "WordPressImport.count", +1 do
      post :create, :import => { :source => fixture_file_upload('/files/word_press/word_press_import.xml') }
    end

    assert_response :ok
    assert_template 'create'
  end
    
  def test_create_should_fail_with_no_input_file
    assert_no_difference "WordPressImport.count" do
      post :create, :import => { }
    end

    assert_response :ok
    assert_template 'new'
    assert flash[:error]
  end

  def test_import_should_succeed_over_html
    post :import, :format => 'html', :id => @import.id
  
    assert_response :redirect
    assert_redirected_to :controller => 'dashboard', :action => 'index'
  end

  def test_import_failing_with_invalid_xml_over_html
    @import.content = File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press/word_press_import_typo.xml').read
    @import.save
    post :import, :id => @import.id, :format => 'html'

    assert_response :redirect
    assert_redirected_to :controller => 'dashboard', :action => 'index'
  end
  
  def test_import_should_fail_with_no_id_over_html
    post :import, :format => 'html'

    assert_response :redirect
    assert_redirected_to :controller => 'dashboard', :action => 'index'
    assert flash[:error]      
    
    post :import, :format => 'html', :id => 'garbage'

    assert_response :redirect
    assert_redirected_to :controller => 'dashboard', :action => 'index'
    assert flash[:error]      
  end
  
  def test_import_should_fail_if_invalid_site_over_html
    @import.shop_url = 'garbage'
    @import.save
    post :import, :id => @import.id, :format => 'html'

    assert_response :redirect
    assert_redirected_to :controller => 'dashboard', :action => 'index'
    assert flash[:error]
  end
  
end
