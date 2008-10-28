require File.dirname(__FILE__) + '/../test_api_helper'
require File.dirname(__FILE__) + '/../../vendor/plugins/shopify_app/lib/shopify_api.rb'
require 'fastercsv'

class OsCommerceImportTest < ActiveSupport::TestCase

  def setup
    @import = OsCommerceImport.new    

    @import.content = File.open(File.dirname(__FILE__) + '/../fixtures/files/os_commerce/import.csv').read
    @import.base_url = 'localhost/os-commerce'
    @import.site = 'localhost'
    @import.save    
  end

  def test_save_data
    ShopifyAPI::Product.any_instance.expects(:save).times(27)
    ShopifyAPI::Image.any_instance.expects(:save).times(27)
    ShopifyAPI::Variant.any_instance.expects(:save).times(27)
    
    assert @import.execute!('localhost')    
  end

  def test_parse
    OsCommerceImport.any_instance.expects(:add_product).times(27)
    
    assert @import.parse
    assert @import.save
  end
  
  def test_parsing
    assert @import.parse    
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
