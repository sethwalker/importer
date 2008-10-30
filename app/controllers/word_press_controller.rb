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
      flash[:error] = "The type of import that you are attempting is not currently supported."
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

      @import.execute!('test')
    rescue REXML::ParseException => e
      flash[:error] = "Error importing blog. Your file is not valid XML."
    rescue ActiveResource::ResourceNotFound => e
      flash[:error] = "Error importing blog. The data could not be saved."
    rescue ActiveRecord::RecordNotFound => e
      flash[:error] = "Either the import job that you are attempting to run does not exist or you are attempting to run someone else's import job..."
    rescue NameError => e
      flash[:error] = "The type of import that you are attempting may not be currently supported."
    else
      flash[:notice] = "Blog successfully imported! You have imported " + help.pluralize(@import.adds.to_hash['post'], 'blog post') + ", " + help.pluralize(@import.adds.to_hash['page'], 'page') + ", and " + help.pluralize(@import.adds.to_hash['comment'], 'comment') + ", with #{@import.skipped} skipped."      
    end
    
    respond_to do |format|
      format.html { redirect_to :controller => 'dashboard', :action => 'index' }
      format.js { render :partial => 'import' }
    end
  end
  
end
