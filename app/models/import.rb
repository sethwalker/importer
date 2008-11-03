class Import < ActiveRecord::Base

  # attr_protected :shop_url
  validates_presence_of  :content, :on => :create      # must have content just on creation of import
  validates_presence_of  :shop_url
  
  before_create :init_serials
  
  serialize :adds, Hash
  serialize :guesses, Hash
  serialize :import_errors, Array

  def init_serials
    self.adds = Hash.new
    self.guesses = Hash.new
    self.import_errors = Array.new
  end
  
  def source=(file_data)
    @file_data = file_data
  end
  
  def write_file
    if @file_data
      content = @file_data.read 
      
      # Gets rid of a REXML exception, in my experience, this tag is always empty
      content.gsub!('<excerpt:encoded><![CDATA[]]></excerpt:encoded>', '')
      self.content = content
    else
      nil
    end
  end
  

  def added(type)
    adds ||= {}
    adds[type] ||= 0
    adds[type] += 1
    save
  end
  
  def guessed(type)   
    guesses ||= {}
    guesses[type] ||= 0
    guesses[type] += 1
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
    adds.each { |key,value| message += "#{value} #{key}s successfully imported.\n"}
    message += "\n"
    guesses.keys.each { |key| message += "#{skipped(key)} #{key}s skipped.\n"}
    message
  end
        
  # Children of this class should overwrite these methods
  def parse 
  end

  def save_data 
  end
  
  def guess 
  end
    
end
