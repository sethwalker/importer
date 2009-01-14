class AdminController < ApplicationController
  before_filter :authenticate
  before_filter :load_import, :except => :index
  
  def index
    @imports = Import.find(:all)
  end
  
  def content
  end
  
  def summary
  end
  
  def errors
  end
  
  private
  
  def load_import
    @import = Import.find(params[:id])
  end
  
  def authenticate
    authenticate_or_request_with_http_basic("Importer Stats") do |user, pass|
      APP_CONFIG['valid_user'] == user and APP_CONFIG['valid_pass'] == pass
    end
  end 
end
