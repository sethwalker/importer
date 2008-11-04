class OsCommerceImportTest < ActiveSupport::TestCase

  def setup
    @import = OsCommerceImport.new    

    @import.content = File.open(File.dirname(__FILE__) + '/../fixtures/files/os_commerce/import.csv').read
    @import.base_url = 'localhost/os-commerce'
    @import.shop_url = 'localhost'
    @import.save    
    
    OsCommerceImport.stubs(:existent_url?).returns(true)
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
end
