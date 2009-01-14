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
        flash[:error] = "Error importing your shop. #{@import.errors.to_a.first.join(" ").gsub(/base_url/, "URL")}" unless flash[:error]
        render :action => "new"
      end
    
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
      @import.send_later(:execute!, session[:shopify].site, Import.email_address)
    rescue ActiveRecord::RecordNotFound => e
      flash[:error] = "Either the import job that you are attempting to run does not exist or you are attempting to run someone else's import job..."
    end
    
    respond_to do |format|
      format.html { redirect_to :controller => 'dashboard', :action => 'index' }
      format.js { render :partial => '/common/import' }
    end
  end
  
  def poll
    @import = OsCommerceImport.find(params[:import_id])

    respond_to do |format|
      format.js { render :partial => '/common/import' }
    end
  end
  
end
