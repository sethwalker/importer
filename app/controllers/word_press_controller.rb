class WordPressController < ApplicationController

  around_filter :shopify_session

  def index
    redirect_to :action => 'new'
  end

  def create
    begin
      @import = WordPressImport.new(params[:import])

      flash[:error] = "Error importing your blog. Wrong file type." unless @import.write_file      
      if @import.save
        @import.guess
#        flash[:notice] = "Your WordPress Export file was successfully uploaded."
      else
        flash[:error] = "Error importing your blog." unless flash[:error]
        #redirect or render?
        render :action => "new"
      end
    
    rescue NameError => e
      flash[:error] = "The type of import that you are attempting is not currently supported."
      redirect_to :action => "new"
    rescue REXML::ParseException => e
      flash[:error] = "Error importing blog. Your file is not valid XML."      
      redirect_to :action => "new"
    end
  end
    
  def new
  end

  def import
    begin
      # Find the import job 
      @import = params[:id] ? WordPressImport.find(params[:id]) : WordPressImport.last_import
      @import.start_time = Time.now
      @import.parse
      @import.save_data
      @import.finish_time = Time.now
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
    
    if request.xhr?    
      render :partial => 'import'
    else
      redirect_to :controller => 'dashboard', :action => 'index'
    end
  end
  
end
