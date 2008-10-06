require File.dirname(__FILE__) + '/../test_api_helper'
require File.dirname(__FILE__) + '/../../vendor/plugins/shopify_app/lib/shopify_api.rb'

class ImportControllerTest < ActionController::TestCase
  
  def setup
    ShopifyAPI::Blog.stubs(:find).returns([])
    ShopifyAPI::Blog.stubs(:comments_enabled?).returns(true)
    
    ShopifyAPI::Page.stubs(:find).returns([])
    ShopifyAPI::Page.stubs(:save).returns(true)
    
    ShopifyAPI::Session.stubs(:create_permission_url).returns('login/finalize')
    ShopifyAPI::Session.stubs(:valid?).returns(true)
    ShopifyAPI::Session.stubs(:site).returns('localhost')
    
    WordPressImport.any_instance.stubs(:parse).returns(true)
    WordPressImport.any_instance.stubs(:save_data).returns(true)     
    
    get 'login/finalize'
    session['shopify'] = ShopifyAPI::Session.new("localhost")
    
    @import = imports(:word_press)
  end
     
   def test_index_should_go_to_login_if_no_session
     session['shopify'] = nil
     get :index

     assert_response :redirect
     assert_redirected_to :controller => 'login'
   end   

   def test_index_should_go_to_import_new_if_session
     get :index

     assert_response :redirect
     assert_redirected_to :controller => 'import', :action => 'new'
   end   
   
   def test_upload_selecting_a_blog_should_pass_the_type_and_ask_for_upload
     get :upload, :type => 'word_press'
     
     assert_template 'upload'
     assert_tag :form, :descendant => { :tag => 'input', :attributes => { :type => 'file' } }
   end  
   
   def test_create_should_create_new_import_job_based_on_type
     assert_difference "WordPressImport.count", +1 do
       post :create, :import => { :source => fixture_file_upload('../fixtures/files/word_press_import.xml', 'image/xml') }, 
          :type => 'word_press'
     end
     
     assert_equal(File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press_import.xml').read, WordPressImport.find(:last).content)
   end
 
   def test_import_redirect_to_dashboard_after_success
     get :import, :type => 'word_press', :id => @import.id

     assert flash[:notice]
     assert_redirected_to :controller => 'dashboard'
   end
   
   def test_import_type
     get :import, :type => 'garbage', :id => @import.id

     assert flash[:error]
     assert_redirected_to :controller => 'dashboard'
   end

   def test_import_id
     get :import, :type => 'word_press', :id => 'garbage'

     assert flash[:error]
     assert_redirected_to :controller => 'dashboard'
   end

end
