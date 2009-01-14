class EbayAccountController < ApplicationController
  skip_before_filter :load_ebay_account
  
  # Testing
  # RUNAME = "jadedPixel-jadedPix-71b0-4-cwyqdsoqv"
  
  # Production
  RUNAME = "jadedPixel-jadedPix-45d6-4-nacpk"
  def index
    # Testing
    # redirect_to "https://signin.sandbox.ebay.com/ws/eBayISAPI.dll?SignIn&runame=#{RUNAME}"    
    
    # Production
    redirect_to "https://signin.ebay.com/ws/eBayISAPI.dll?SignIn&runame=#{RUNAME}"
  end

  def accept                 
    
    shop = ShopifyAPI::Shop.current
    
    EbayAccount.create(
      :ebay_id           => params[:username],
      :ebay_token        => params[:ebaytkn],
      :ebay_token_expiry => params[:tknexp],
      :ebay_site_id      => 0, # US Default
      :paypal_account    => '',
      :shop              => current_shop.site,
      :currency          => shop.currency,
      :country           => shop.country, 
      :province          => shop.province,
      :city              => shop.city,
      :time_zone         => shop.timezone
    )
    
    redirect_to '/ebay'
  end
  
  def reject
  end
  
  def policy
  end
end
