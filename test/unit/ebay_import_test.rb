require 'test_helper'

class EbayImportTest < ActiveSupport::TestCase
  def setup
    @import = EbayImport.new

    @import.content = "Somethin'"
    @import.shop_url = 'shopify.myshopify.com'
    assert @import.save
  end
  
  test "execute should run everything" do
    @import.expects(:parse_and_save_data).times(1)

    assert_difference "ActionMailer::Base.deliveries.size" do
      assert @import.execute!('user:pass.shopify.myshopify.com', 'shop@shopify.com')
    end

    assert_equal ['shop@shopify.com'], ActionMailer::Base.deliveries.first.to
  end
end