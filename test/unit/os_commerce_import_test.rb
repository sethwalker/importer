class OsCommerceImportTest < ActiveSupport::TestCase

  def setup
    @import = OsCommerceImport.new    

    @import.content = File.open(File.dirname(__FILE__) + '/../fixtures/files/os_commerce/import.csv').read
    @import.base_url = 'localhost/os-commerce'
    @import.shop_url = 'localhost'
    @import.save    
    
    OsCommerceImport.stubs(:existent_url?).returns(true)
  end

  def test_save_data
    ShopifyAPI::Product.any_instance.expects(:save).times(27).returns(true)
    ShopifyAPI::Product.stubs(:find).returns(nil)
    
    ShopifyAPI::Image.stubs.expects(:save).times(27).returns(true)
    ShopifyAPI::Variant.any_instance.expects(:save).times(37).returns(true)
    ShopifyAPI::CustomCollection.any_instance.expects(:save).times(3).returns(true)
    ShopifyAPI::Collect.any_instance.expects(:save).times(27).returns(true)
    
    assert @import.parse
    assert @import.save_data
    assert @import.save
  end

  def test_parse
    OsCommerceImport.any_instance.expects(:add_product).times(27)
    
    assert @import.parse
    assert @import.save
  end
  
  def test_guess
    @import.guess

    assert_equal 27, @import.guesses['product']
  end
  
# 
#   def test_skipped
#     # mocks
#     
#     @import.guess    
#     @import.parse
#     @import.save_data
# 
#     assert_equal 0, @import.skipped
#   end
# 
#   def test_original_url
#   end
# 
#   def test_guess
#     @import.guess
# 
#     # assert_equal actual, guess
#   end
# 
#   def test_should_throw_exception_if_csv_is_invalid
#     @import.content = # some invalid csv
#     @import.save
# 
# #    assert_raise CSV::ParseException do 
#       @import.parse
# #    end
#   end
# 
#   def test_should_throw_exception_if_csv_format_is_invalid
#     @import.content = # valid csv, wrong formate
#     @import.save
# 
#     # assert_raise NoMethodError do 
#     #   @import.parse
#     # end
#   end  
end
