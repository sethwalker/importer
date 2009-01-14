require 'test_helper'

class OsCommerceImportTest < ActiveSupport::TestCase

  def setup
    @import = OsCommerceImport.new    

    @import.content = File.open(File.dirname(__FILE__) + '/../fixtures/files/os_commerce/import.csv').read
    @import.base_url = 'http://demo.oscommerce.com'
    @import.shop_url = 'jessetesting.myshopify.com'
    @import.save    
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
  
  def test_should_not_create_import_wihtout_content
    @new_import = OsCommerceImport.new
    assert !@new_import.save
    
    @new_import.content = 'test'
    @new_import.save
  end
end