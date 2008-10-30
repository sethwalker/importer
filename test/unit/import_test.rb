require File.dirname(__FILE__) + '/../test_helper'

class ImportTest < ActiveSupport::TestCase
  
  def setup
    @import = WordPressImport.new(:content => File.read(File.dirname(__FILE__) + '/../fixtures/files/word_press/word_press_import.xml'))
    @import.shop_url = 'localhost.myshopify.com'
    @import.save
  end
    
  def test_saving_model_should_write_file_to_db
    @data = File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press/word_press_import.xml')
    @original_data = @data.read
    @new_import = Import.new( :content => @original_data)
    @new_import.save

    assert_equal @original_data, @new_import.content
  end
  
  def test_should_not_create_import_wihtout_content
    @new_import = Import.new()
    assert !@new_import.save
  end
  
  def test_should_be_able_to_add_and_guess
    @import.adds['post'] = @import.adds['page'] = @import.guesses['post'] = @import.guesses['page'] = 0
    assert_difference "@import.adds['post']", +1 do
      @import.added('post')
    end    
    assert_difference "@import.adds['page']", +1 do
      @import.added('page')
    end
    assert_difference "@import.guesses['post']", +1 do
      @import.guessed('post')
    end    
    assert_difference "@import.guesses['page']", +1 do
      @import.guessed('page')
    end
    assert @import.save
  end
    
  def test_should_not_allow_creation_of_import_without_content
    @import = Import.new
    assert !@import.save
  end
  
  def test_should_not_save_without_site
    @import = Import.new( :content => "meaningless" )
    assert !@import.save
    
    @import.shop_url = "http://testing.com"
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
  
  def test_creation_should_init_guesses_errors_and_adds
    @import = WordPressImport.new(:content => 'test')
    @import.shop_url = 'test'

    [@import.adds, @import.guesses, @import.import_errors].each do |attrib|
      assert_equal nil, attrib
    end
    
    assert @import.save
    
    [@import.adds, @import.guesses].each do |hash|
      assert_equal({}, hash)
    end
    
    assert_equal [], @import.import_errors
  end
  
  def test_shop_url_should_be_protected
    @import = WordPressImport.new(:shop_url => 'test', :content => 'test')
    assert !@import.save
    
    @import.shop_url = 'test'
    assert @import.save
  end
end
