require 'ostruct'
require 'digest/md5'

module ShopifyAPI  
  # Create a new session 
  #
  # Example:
  #   class LoginController < ApplicationController
  #     layout 'empty'
  #     
  #     def index
  #        # ask user for his myshopify.com address. 
  #     end
  #   
  #     def authenticate
  #       redirect_to ShopifyAPI::Session.new(params[:shop]).create_permission_url    
  #     end
  #   
  #     def finalize
  #       shopify_session = ShopifyAPI::Session.new(params[:shop], params[:t])
  #       if shopify_session.valid?          
  #         redirect_to # logged in area
  #       else
  #         flash[:notice] = "Could log in to shopify store."
  #         redirect_to :action => 'index'
  #       end
  #     end
  #   end
  #    
  class Session
    cattr_accessor :api_key
    cattr_accessor :secret
    cattr_accessor :protocol 
    self.protocol = 'https'

    attr_accessor :url, :token, :name
    
    def self.setup(params)
      params.each { |k,value| send("#{k}=", value) }
    end

    def initialize(url, token = nil)
      url.gsub!(/https?:\/\//, '')                            # remove http://
      url = "#{url}.myshopify.com" unless url.include?('.')   # extend url to myshopify.com if no host is given
      
      self.url, self.token = url, token
    end
    
    def shop
      Shop.current
    end
    
    # mode can be either r to request read rights or w to request read/write rights.
    def create_permission_url(mode = 'w')
      "http://#{url}/admin/api/auth?api_key=#{api_key}&mode=#{mode}"
    end

    # use this to initialize ActiveResource:
    # 
    #  ActiveResource::Base.site = Shopify::Session.new(session[:shop], session[:t]).site
    #
    def site
      "#{protocol}://#{api_key}:#{computed_password}@#{url}/admin"
    end

    def valid?
      [url, token].all?
    end

    private

    # The secret is computed by taking the shared_secret which we got when 
    # registring this third party application and concating the request_to it, 
    # and then calculating a MD5 hexdigest. 
    def computed_password
      Digest::MD5.hexdigest(secret + token.to_s)
    end
  end

  # Shop object. Use Shop.current to receive 
  # the shop. Since you can only ever reference your own
  # shop this model does not have a .find method.
  #
  class Shop
    def self.current
      ActiveResource::Base.find(:one, :from => "/admin/shop.xml")
    end
  end               

  # Custom collection
  #
  class CustomCollection < ActiveResource::Base
    def products
      Product.find(:all, :params => {:collection_id => self.id})
    end
    
    def add_product(product)
      Collect.create(:collection_id => self.id, :product_id => product.id)
    end
    
    def remove_product(product)
      collect = Collect.find(:first, :params => {:collection_id => self.id, :product_id => product.id})
      collect.destroy if collect
    end
  end                                                                 

  # For adding/removing products from custom collections
  class Collect < ActiveResource::Base
  end

  class ShippingAddress < ActiveResource::Base
  end

  class BillingAddress < ActiveResource::Base
    def name
      "#{first_name} #{last_name}"
    end
  end         

  class LineItem < ActiveResource::Base 
  end       

  class ShippingLine < ActiveResource::Base
  end  

  # Order model
  #
  class Order < ActiveResource::Base  

    def close; load_attributes_from_response(post(:close)); end

    def open; load_attributes_from_response(post(:open)); end

    def transactions
      Transaction.find(:all, :params => { :order_id => id })
    end
    
    def capture(amount = "")
      Transaction.create(:amount => amount, :kind => "capture", :order_id => id)
    end
  end

  # Shopify product
  class Product < ActiveResource::Base

    # Share all items of this store with the 
    # shopify marketplace
    def self.share; post :share;  end    
    def self.unshare; delete :share; end

    # compute the price range
    def price_range
      prices = variants.collect(&:price)
      format =  "%0.2f"
      if prices.min != prices.max
        "#{format % prices.min} - #{format % prices.max}"
      else
        format % prices.min
      end
    end
    
    def collections
      CustomCollection.find(:all, :params => {:product_id => self.id})
    end
    
    def add_to_collection(collection)
      collection.add_product(self)
    end
    
    def remove_from_collection(collection)
      collection.remove_product(self)
    end
  end
  
  class Variant < ActiveResource::Base
    self.prefix = "/admin/products/:product_id/"
  end
  
  class Image < ActiveResource::Base
    self.prefix = "/admin/products/:product_id/"
    
    # generate a method for each possible image variant
    [:pico, :icon, :thumb, :small, :medium, :large, :original].each do |m|
      reg_exp_match = "/\\1_#{m}.\\2"
      define_method(m) { src.gsub(/\/(.*)\.(\w{2,4})/, reg_exp_match) }
    end
    
    def attach_image(data, filename = nil)
      attributes[:attachment] = Base64.encode64(data)
      attributes[:filename] = filename unless filename.nil?
    end
  end

  class Transaction < ActiveResource::Base
    self.prefix = "/admin/orders/:order_id/"
  end
      
  class Country < ActiveResource::Base
  end

  class Page < ActiveResource::Base
  end
  
  class Blog < ActiveResource::Base
    def articles
      Article.find(:all, :params => { :blog_id => id })
    end
  end
  
  class Article < ActiveResource::Base
    self.prefix = "/admin/blogs/:blog_id/"
  end

  class Comment < ActiveResource::Base
  end
  
  class Province < ActiveResource::Base
    self.prefix = "/admin/countries/:country_id/"
  end
end