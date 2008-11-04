require File.dirname(__FILE__) + '/../test_helper'

class WordPressImportTest < ActiveSupport::TestCase

  def setup
    @import = WordPressImport.new(:content => File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press/word_press_import.xml').read)
    @import.shop_url = 'localhost.myshopify.com'
    assert @import.save    
  end
  
  def test_save_data
    ShopifyAPI::Article.any_instance.expects(:save).times(8)
    ShopifyAPI::Blog.any_instance.expects(:save).times(1)
    ShopifyAPI::Page.any_instance.expects(:save).times(2)
    ShopifyAPI::Comment.any_instance.expects(:save).times(3)

    @import.parse    
    @import.save_data
  end
  
  def test_parse
    WordPressImport.any_instance.expects(:add_page).times(1)
    WordPressImport.any_instance.expects(:add_article).times(4)

    @import.parse
  end
  
  def test_skipped
    ShopifyAPI::Article.any_instance.expects(:save).times(8).returns(true)
    ShopifyAPI::Blog.any_instance.expects(:save).times(1).returns(true)
    ShopifyAPI::Page.any_instance.expects(:save).times(2).returns(true)
    ShopifyAPI::Comment.any_instance.expects(:save).times(3).returns(true)
    
    @import.guess    
    @import.parse
    @import.save_data
    
    assert_equal 4, @import.adds['article']
    assert_equal 1, @import.adds['page']
    assert_equal 3, @import.adds['comment']

    assert_equal 0, @import.skipped('article')
    assert_equal 0, @import.skipped('page')
    assert_equal 0, @import.skipped('comment')    
  end
  
  def test_blog_title
    assert_equal "Jesse's WordPress Blog", @import.blog_title
  end

  def test_original_url
    assert_equal 'http://localhost/wordpress', @import.original_url
  end
  
  def test_guess
    @import.guess
    
    assert_equal 4, @import.guesses['article']
    assert_equal 1, @import.guesses['page']
    assert_equal 3, @import.guesses['comment']
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
