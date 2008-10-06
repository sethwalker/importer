class ImportController < ApplicationController

  around_filter :shopify_session, :except => 'welcome'

  def index
    redirect_to :action => 'new'
  end

  def new
  end

  def create
    begin
      eval "@import = #{params[:type].camelize}Import.new(params[:import])"

      flash[:error] = "Error importing your blog. Wrong file type." unless @import.write_file      
      if @import.save
        flash[:notice] = "Your WordPress Export file was successfully uploaded."
        @import.guess
      else
        flash[:error] = "Error importing your blog." unless flash[:error]
        render :action => "new"
      end
    
    rescue NameError => e
      flash[:error] = "The type of import that you are attempting is not currently supported."
      render :action => "new"
    end
  end
    
  def upload
  end

  def import
    begin
      # Find the import job 
      eval "@import = #{params[:type].camelize}Import.find(params[:id])"
      @import.parse
      @import.save_data
    rescue REXML::ParseException => e
      flash[:error] = "Error importing blog. Your file is not valid XML."
    rescue ActiveResource::ResourceNotFound => e
      flash[:error] = "Error importing blog. The data could not be saved."
    rescue ActiveRecord::RecordNotFound => e
      flash[:error] = "The import job that you are attempting to run does not exist. Are you sure that it didn't finish already?"
    rescue NameError => e
      flash[:error] = "The type of import that you are attempting is not currently supported."
    else
      flash[:notice] = "Blog successfully imported! You have imported " + help.pluralize(@import.posts, 'blog post') + ", " + help.pluralize(@import.pages, 'page') + ", and " + help.pluralize(@import.comments, 'comment') + ", with #{@import.skipped} skipped."      
    end
        
    redirect_to :controller => 'dashboard', :action => 'index'
  end
  
end
