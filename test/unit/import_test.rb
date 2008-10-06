require File.dirname(__FILE__) + '/../test_helper'

class ImportTest < ActiveSupport::TestCase
  
  def setup
    @import = Import.new    
  end
    
  def test_saving_model_should_write_file_to_db
    @data = File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press_import.xml')
    @original_data = @data.read
    @import.content = @original_data
    @import.save

    assert_equal @original_data, @import.content
  end
  
  def test_should_be_able_to_add_posts_pages_and_comments
    assert_difference '@import.posts', +1 do
      @import.added('post')
    end
    
    assert_difference '@import.pages', +1 do
      @import.added('page')
    end
    
    assert_difference '@import.comments', +1 do
      @import.added('comment')
    end    
  end
  
  def test_should_not_allow_creation_of_import_without_content
    @import = Import.new
    assert !@import.save
  end
  
end
