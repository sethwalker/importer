require File.dirname(__FILE__) + '/../test_api_helper'
require File.dirname(__FILE__) + '/../../vendor/plugins/shopify_app/lib/shopify_api.rb'

class WordPressControllerTest < ActionController::TestCase
  
  def setup
    ShopifyAPI::Blog.stubs(:comments_enabled?).returns(true)
    
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

   def test_create_should_create_new_import_job_based_on_type
     assert_difference "WordPressImport.count", +1 do
       post :create, :import => { :source => fixture_file_upload('../fixtures/files/word_press_import.xml', 'text/xml') }
     end
     
     assert_equal(File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press_import.xml').read, WordPressImport.find(:last).content)
   end

   def test_create_should_not_succeed_with_invalid_file_type
     assert_no_difference "WordPressImport.count" do
         post :create, :import => { :source => fixture_file_upload('../fixtures/files/postsxml.zip', 'text/xml') }
     end

     assert flash[:error]
     assert_template 'new'
   end
   
   def test_create_should_redirect_to_new_if_import_not_save
     
   end
   
   #create name error and parse exception
   
   def test_create_should_guess_if_import_saves
     
   end
   
   def test_upload_selecting_a_blog_should_pass_the_type_and_ask_for_upload
     get :new
     
     assert_template 'new'
     assert_tag :form, :descendant => { :tag => 'input', :attributes => { :type => 'file' } }
   end  
   
   #more for upload (testing xhr and partials!!)
 
end
