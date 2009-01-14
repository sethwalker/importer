ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class Test::Unit::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false

  fixtures :all

  # Add more helper methods to be used by all tests here...  
  def set_shopify_session
    get 'login/finalize'
    session['shopify'] = ShopifyAPI::Session.new("localhost")
  end
  
  def set_ebay_session
    acct = EbayAccount.create(
      :ebay_id           => 'shopify-test',
      :ebay_token        => 'longuglystring',
      :ebay_token_expiry => '2010-06-08 20:01:59',
      :ebay_site_id      => 0, # US Default
      :paypal_account    => '',
      :shop              => 'user:pass.localhost',
      :currency          => 'USD',
      :country           => 'US', 
      :province          => 'California',
      :city              => 'San Fran',
      :time_zone         => 'EST'
    )

    EbayAccount.stubs(:find_by_shop).returns(acct)
  end
  
  Import.stubs(:existent_url?).returns(true)
  Import.stubs(:email_address).returns('shop@shopify.com')

  ActiveResource::Base.site = 'testing.com'
  
  def set_http_auth(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("#{user}:#{pass}")
  end
end
