class Import < ActiveRecord::Base

  attr_protected :shop_url
  validates_presence_of  :content, :on => :create      # must have content just on creation of import
  validates_presence_of  :shop_url
  
  before_create :init_serials
  
  serialize :adds
  serialize :guesses
  serialize :import_errors

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
  
  def guessed(type)
    if not self.guesses[type] then self.guesses[type] = 1 else self.guesses[type] += 1 end
    self.save
  end

  def added(type)
    if not self.adds[type] then self.adds[type] = 1 else self.adds[type] += 1 end
    self.save
  end
  
  def finished?
    !finish_time.blank?
  end
        
  # Children of this class should overwrite these methods
  def parse 
  end

  def save_data 
  end
  
  def guess 
  end
  
  def skipped 
  end
    
  def blog_title
  end
  
  def original_url
  end

end
