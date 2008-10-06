#require "ftools"

class Import < ActiveRecord::Base

  attr_accessible :content, :posts, :pages, :comments, :posts_guess, :pages_guess, :comments_guess, :source, :start_time, :finish_time
  validates_presence_of  :content, :on => :create      # must have content just on creation of import

  def source=(file_data)
    @file_data = file_data
  end

  def write_file
    if @file_data
      content = @file_data.read 
      
      # Gets rid of a REXML exception, in my experience, this tag is always empty
      content.gsub!('<excerpt:encoded><![CDATA[]]></excerpt:encoded>', '')
      self.content = content
    end
  end

  def guessed(type)
    case type
      when 'post' then self.posts_guess += 1
      when 'page' then self.pages_guess += 1
      when 'comment' then self.comments_guess += 1
    end
    self.save
  end

  def added(type)
    case type
      when 'post' then self.posts = self.posts + 1
      when 'page' then self.pages = self.pages + 1
      when 'comment' then self.comments = self.comments + 1
    end
    self.save
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
