class DashboardController < ApplicationController
  
  around_filter :shopify_session, :except => 'welcome'
  
  def index
    @products = ShopifyAPI::Product.find(:all)
    @orders   = ShopifyAPI::Order.find(:all, :params => {:limit => 5})

    @articles = []
    @blogs = ShopifyAPI::Blog.find(:all)
    # Get recent articles from each blog
    @blogs.each do |blog|
      @articles += ShopifyAPI::Article.find(:all, :params => {:blog_id => blog.id}, :limit => 5)
    end
    # Truncate to only the latest 5 articles
    @articles = @articles.sort_by(&:updated_at)[0..4].reverse
  end
  
  # def download_web_image
  #   return true unless @src
  #   
  #   file = WebFile.new(@src)
  #   
  #   unless FileSystem.content_type_accepted?(file.content_type, :images)
  #     errors.add_to_base("#{file.filepath} is not a valid product image file type.")
  #     return false
  #   end
  #   
  #   if file.size.nil? || file.size == 0
  #     errors.add_to_base("#{file.filepath} is not a valid product image.")
  #     return false
  #   end
  #   
  #   # sometimes file.size is nil. How to handle this?
  #   
  #   if file.size > 10.megabytes
  #     errors.add_to_base("#{file.filepath} is too large. The maximum file size for a product image is 10MB.")
  #     return false
  #   end
  #   
  #   self.filepath = determine_filepath("#{File.basename(file.filepath, ".*")}#{mime_types.index(file.content_type)}")
  #   write(file.read)
  #   
  #   return true
  # rescue WebFile::Error => e
  #   errors.add_to_base(e.message)
  #   return false
  # end
  
  def welcome
  end
  
end