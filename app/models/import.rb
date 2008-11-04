class Import < ActiveRecord::Base
  
  attr_protected :shop_url
  validates_presence_of  :content, :on => :create      # must have content just on creation of import
  validates_presence_of  :shop_url
  
  before_create :init_serials
  
  serialize :adds, Hash
  serialize :guesses, Hash  
  serialize :import_errors, Array
  
  def init_serials
    self.import_errors = []
  end
  
  def source=(file_data)
    @file_data = file_data
  end
  
  def write_file
    if @file_data && !@file_data.blank?
      content = @file_data.read 
      
      # Gets rid of a REXML exception, in my experience, this tag is always empty
      content.gsub!('<excerpt:encoded><![CDATA[]]></excerpt:encoded>', '')
      self.content = content
    else
      nil
    end
  end
  
  def added(type)
    self.adds ||= {}
    self.adds[type] ||= 0
    self.adds[type] += 1
    self.adds_will_change!
    save
  end
  
  def guessed(type) 
    self.guesses ||= {}
    self.guesses[type] ||= 0
    self.guesses[type] += 1
    self.guesses_will_change!
    save
  end
  
  def finished?
    !finish_time.blank?
  end
  
  def skipped(type)
    guesses[type].to_i - adds[type].to_i
  end
  
  def mail_message
    message = ""
    adds.each { |key,value| message += "#{value} #{key}s successfully imported.\n"} if adds
    message += "\n"
    guesses.keys.each { |key| message += "#{skipped(key)} #{key}s skipped.\n"} if guesses
    message
  end
  
  # Put it all together !
  def execute!(site, email_recipient)
    if self.start_time.blank? # guard against executing the job multiple times
    
      # initialize
      ShopifyAPI::Product.superclass.site = site # this is for DJ, it can't seem to find the site at execution time unless (perhaps because it comes from session[:shopify] ?)
      self.start_time = Time.now
      
      # parse data
      begin
        parse
      rescue NameError => e
       import_errors << "There was an error parsing your import file."
      rescue CSV::IllegalFormatError => e
        import_errors << "There was an error parsing your import file. Your import file is not a valid CSV file."      
      rescue REXML::ParseException => e
        import_errors << "There was an error parsing your import file. Your import file is not a valid XML file."      
      end
    
      # save data
      begin
        save_data
      rescue ActiveResource::ResourceNotFound => e
        import_errors << "Error importing your shop. Some data could not be saved."
      rescue ActiveResource::ServerError => e
        import_errors << "Error importing your shop. Some data could not be saved."
      rescue ActiveResource::ClientError => e
        import_errors << "So far, you have imported #{adds['product'] || 0} products. This seems to be the maximum number of allowed products for your subscription plan. Please <a href='http://#{shop_url}/admin/accounts/'>upgrade your subscription</a> to allow for more products."
      end
      
      # wrap it up
      self.finish_time = Time.now
      self.save
      
      # email
      SummaryMailer.deliver_summary(base_url, email_recipient, mail_message)
    end
  end
  
  # class methods
  def Import.email_address
    http = Net::HTTP.new(ShopifyAPI::Product.superclass.site.host, ShopifyAPI::Product.superclass.site.port)
    http.use_ssl = true
    
    req = Net::HTTP::Get.new("/admin/shop.xml")
    req.basic_auth(ShopifyAPI::Product.superclass.site.user, ShopifyAPI::Product.superclass.site.password)
    
    response = http.request(req)
    REXML::XPath.first(REXML::Document.new(response.body), "//email").text
  end
        
  # Children of this class should overwrite these methods
  def parse 
  end

  def save_data 
  end
  
  def guess 
  end
    
end
