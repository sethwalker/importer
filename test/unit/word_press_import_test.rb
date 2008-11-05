require File.dirname(__FILE__) + '/../test_api_helper'

class WordPressImportTest < ActiveSupport::TestCase

  def setup
    @import = WordPressImport.new(:content => File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press/word_press_import.xml').read)
    @import.shop_url = 'localhost.myshopify.com'
    assert @import.save    
  end
  
  def test_blog_title
    assert_equal "Jesse's WordPress Blog", @import.blog_title
  end

  def test_original_url
    assert_equal 'http://localhost/wordpress', @import.original_url
  end
  
  def test_guess
    assert @import.guess
    assert @import.save
    
    assert_equal 4, @import.guesses['article']
    assert_equal 1, @import.guesses['page']
    assert_equal 3, @import.guesses['comment']
  end
  
  def test_parse
    WordPressImport.any_instance.expects(:add_article).times(4)
    WordPressImport.any_instance.expects(:add_page).times(1)
    
    assert @import.parse
    assert @import.save
  end
  
  def test_save_data
    ShopifyAPI::Article.any_instance.expects(:save).times(8)
    ShopifyAPI::Comment.any_instance.expects(:save).times(3)
    ShopifyAPI::Page.any_instance.expects(:save).times(2)
    ShopifyAPI::Blog.any_instance.expects(:save).times(1)
    
    assert @import.parse
    assert @import.save_data
    assert @import.save
  end
  
  def test_should_throw_exception_if_xml_is_invalid
    @import.content = '<?xml version="1.0" encoding="UTF-8"?> <wordpress> <<<stuff>'
    @import.save

    assert_raise REXML::ParseException do 
      @import.parse
    end
  end

  def test_should_throw_exception_if_xml_format_is_invalid
    @import.content = '<?xml version="1.0" encoding="UTF-8"?> <wordpress> </wordpress>'
    @import.save

    assert_raise NoMethodError do 
      @import.parse
    end
  end  
end
