require 'csv'

class OsCommerceController < ApplicationController

  around_filter :shopify_session

  def index
    redirect_to :action => 'new'
  end
  
  def new
  end

  def create
    begin
      @import = OsCommerceImport.new(params[:import])
      @import.shop_url = current_shop.url

      flash[:error] = "Error importing your shop. Wrong file type or corrupt file." if not @import.write_file
      if @import.save
        @import.guess
      else
        flash[:error] = "Error importing your shop." unless flash[:error]
        render :action => "new"
      end
    
    # rescue NameError => e
    #   flash[:error] = "The type of import that you are attempting is not currently supported."
    #   render :action => "new"
    rescue CSV::IllegalFormatError => e
      flash[:error] = "Error importing your shop. Your import file is not a valid CSV file."      
      render :action => "new"
    end
  end

  def import
    # this is an error-free zone!
    flash[:error] = nil
    
    begin
      # Find the import job 
      @import = OsCommerceImport.find(params[:id])

      raise ActiveRecord::RecordNotFound if @import.shop_url != current_shop.url

      @import.update_attribute :submitted_at, Time.now
      @import.execute!(session[:shopify].site, email_address)
    rescue ActiveRecord::RecordNotFound => e
      flash[:error] = "Either the import job that you are attempting to run does not exist or you are attempting to run someone else's import job..."
    end
    
    respond_to do |format|
      format.html { redirect_to :controller => 'dashboard', :action => 'index' }
      format.js { render :partial => 'import' }
    end
  end
  
  def poll
    @import = OsCommerceImport.find(params[:import_id])

    respond_to do |format|
      format.js { render :partial => 'import' }
    end
  end
  
  private
  
  def email_address
    http = Net::HTTP.new(ShopifyAPI::Product.superclass.site.host, ShopifyAPI::Product.superclass.site.port)
    http.use_ssl = true
    
    req = Net::HTTP::Get.new("/admin/shop.xml")
    req.basic_auth(ShopifyAPI::Product.superclass.site.user, ShopifyAPI::Product.superclass.site.password)
    
    response = http.request(req)
    REXML::XPath.first(REXML::Document.new(response.body), "//email").text
  end
  
end
