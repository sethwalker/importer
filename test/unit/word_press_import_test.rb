require File.dirname(__FILE__) + '/../test_helper'

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
