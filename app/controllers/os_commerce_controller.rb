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
      @import.site = current_shop.url

      flash[:error] = "Error importing your shop. Wrong file type." unless @import.write_file
      if @import.save
        @import.guess
      else
        flash[:error] = "Error importing your shop." unless flash[:error]
        render :action => "new"
      end
    
    rescue NameError => e
      flash[:error] = "The type of import that you are attempting is not currently supported."
      render :action => "new"
    rescue REXML::ParseException => e
      flash[:error] = "Error importing your shop. Your import file is not a valid CSV file."      
      render :action => "new"
    end
  end

  def import
    begin
      # Find the import job 
      @import = OsCommerceImport.find(params[:id])
      unless @import.site == current_shop.url
        raise ActiveRecord::RecordNotFound
      end
      @import.execute!() 
    # rescue REXML::ParseException => e
    #   flash[:error] = "Error importing your shop. Your import file is not a valid CSV file."
    rescue ActiveResource::ResourceNotFound => e
      flash[:error] = "Error importing your shop. The data could not be saved."
    # rescue ActiveResource::ServerError => e
    #   flash[:error] = "Error importing your shop. The data could not be saved."
    # rescue ActiveResource::ClientError => e
    #   flash[:error] = "You have reached the maximum number of allowed products for your shop. Please upgrade your subscription to allow for more products."
    # rescue ActiveRecord::RecordNotFound => e
    #   flash[:error] = "Either the import job that you are attempting to run does not exist or you are attempting to run someone else's import job..."
    # rescue NameError => e
    #   flash[:error] = "The type of import that you are attempting may not be currently supported."
    else
      flash[:notice] = "Shop successfully imported! You have imported blah blah fill this in."
    end
    
    respond_to do |format|
      format.html { redirect_to :controller => 'dashboard', :action => 'index' }
      format.js { render :partial => 'import' }
    end
  end
  
end
