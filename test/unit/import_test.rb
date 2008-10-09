require File.dirname(__FILE__) + '/../test_helper'

class ImportTest < ActiveSupport::TestCase
  
  def setup
    @import = imports(:word_press)
  end
    
  def test_saving_model_should_write_file_to_db
    @data = File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press_import.xml')
    @original_data = @data.read
    @new_import = Import.new( :content => @original_data)
    @new_import.save

    assert_equal @original_data, @new_import.content
  end
  
  def test_should_not_create_import_wihtout_content
    @new_import = Import.new()
    assert !@new_import.save
  end
  
  def test_should_be_able_to_add_and_guess_posts_pages_and_comments
    assert_difference '@import.posts', +1 do
      @import.added('post')
    end    
    assert_difference '@import.pages', +1 do
      @import.added('page')
    end
    assert_difference '@import.comments', +1 do
      @import.added('comment')
    end    
    assert_difference '@import.posts_guess', +1 do
      @import.guessed('post')
    end    
    assert_difference '@import.pages_guess', +1 do
      @import.guessed('page')
    end
    assert_difference '@import.comments_guess', +1 do
      @import.guessed('comment')
    end    
  end
    
  def test_should_not_allow_creation_of_import_without_content
    @import = Import.new
    assert !@import.save
  end
  
  def test_should_not_save_without_site
    @import = Import.new( :content => "meaningless" )
    assert !@import.save
    
    @import.site = "http://testing.com"
    assert @import.save
  end
  
  def test_start_time_and_finish_time
    start = 5.minutes.ago
    @import.start_time = start
    assert_equal start, @import.start_time
    
    finish = Time.now
    @import.finish_time = finish
    assert_equal finish, @import.finish_time
  end
end
