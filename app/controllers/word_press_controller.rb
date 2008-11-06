class WordPressController < ApplicationController

  around_filter :shopify_session

  def index
    redirect_to :action => 'new'
  end
  
  def new
  end

  def create
    begin
      @import = WordPressImport.new(params[:import])
      @import.shop_url = current_shop.url

      flash[:error] = "Error importing your blog. Wrong file type." unless @import.write_file
      if @import.save
        @import.guess
      else
        flash[:error] = "Error importing your blog." unless flash[:error]
        render :action => "new"
      end

    rescue NameError => e
      flash[:error] = "There was an error parsing your input file."
      render :action => "new"
    rescue REXML::ParseException => e
      flash[:error] = "Error importing blog. Your file is not valid XML."      
      render :action => "new"
    end
  end

  def import
    begin
      # Find the import job 
      @import = WordPressImport.find(params[:id])
      
      raise ActiveRecord::RecordNotFound if @import.shop_url != current_shop.url

      @import.update_attribute :submitted_at, Time.now
      @import.send_later(:execute!, session[:shopify].site, Import.email_address)
    rescue ActiveRecord::RecordNotFound => e
      flash[:error] = "Either the import job that you are attempting to run does not exist or you are attempting to run someone else's import job..."
    end
    
    respond_to do |format|
      format.html { redirect_to :controller => 'dashboard', :action => 'index' }
      format.js { render :partial => '/os_commerce/import' }
    end
  end
  
  def poll
    @import = WordPressImport.find(params[:import_id])

    respond_to do |format|
      format.js { render :partial => 'os_commerce/import' }
    end
  end
  
end
