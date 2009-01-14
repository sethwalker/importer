require 'ebay'

class EbayController < ApplicationController
  around_filter :shopify_session
  before_filter :load_ebay_account
  helper_method :current_account
  
  def index
    redirect_to :action => 'new'
  end
  
  def new
  end
  
  def preview
    @items_list = []
    
    begin
      response = current_account.ebay.get_my_ebay_selling(
        :active_list => Ebay::Types::ItemListCustomization.new(
          :pagination => Ebay::Types::Pagination.new( :entries_per_page => 2, :page_number => 1 )
        ),
        :unsold_list => Ebay::Types::ItemListCustomization.new(
          :pagination => Ebay::Types::Pagination.new( :entries_per_page => 2, :page_number => 1 )
        )
      )

      response.active_list.items.each do |item|
        item_response = current_account.ebay.get_item(:item_id => item.item_id)
        @items_list << item_response.item
      end rescue nil
      
      response.unsold_list.items.each do |item|
        item_response = current_account.ebay.get_item(:item_id => item.item_id)
        @items_list << item_response.item
      end rescue nil
      
    end

    respond_to do |format|
      format.js { }
    end

    rescue Ebay::RequestError => e
      @err = e    
  end
  
  def import
    @import = EbayImport.new(:ebay_account => current_account)
    @import.shop_url = current_shop.url
    
    @import.update_attribute :submitted_at, Time.now
    @import.send_later(:execute!, session[:shopify].site, Import.email_address)
    
    respond_to do |format|
      format.html { redirect_to root_path }
      format.js { render :partial => '/common/import' }
    end
    
    rescue Ebay::RequestError => e
      flash[:error] = e
  end
  
  def poll
    @import = EbayImport.find(params[:import_id])

    respond_to do |format|
      format.js { render :partial => '/common/import' }
    end
  end
  

  private
  def current_account
    @current_account
  end

  protected
  def load_ebay_account
    if not @current_account = EbayAccount.find_by_shop(current_shop.site)
      redirect_to :controller => 'ebay_account'
    end
  end

  rescue_from Ebay::RequestError do |e|    
    render :text => "<h1>Ebay error</h1>\n\n" + e.errors.collect(&:long_message).join("<br/>\n")
  end  
end