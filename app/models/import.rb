class Import < ActiveRecord::Base

  attr_protected :site
  validates_presence_of  :content, :on => :create      # must have content just on creation of import
  validates_presence_of  :site, :on => :save
  
  before_create :init_hash
  
  serialize :adds
  serialize :guesses

  def init_hash
    puts "===== INIT HASH"
    self.adds = Hash.new
    self.guesses = Hash.new
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
  
  def increase_guess(type)
  end

  def increase_add(type)
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
