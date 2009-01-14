require 'test_helper'

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
  
  def test_should_not_create_import_wihtout_content
    @new_import = WordPressImport.new
    assert !@new_import.save
    
    @new_import.content = 'test'
    @new_import.save
  end
  
  def test_guess
    assert @import.guess
    assert @import.save
    
    assert_equal 4, @import.guesses['article']
    assert_equal 1, @import.guesses['page']
    assert_equal 3, @import.guesses['comment']
  end
  
  def test_parse
    ShopifyAPI::Blog.any_instance.stubs(:save).returns(true)
    
    WordPressImport.any_instance.expects(:add_article).times(4)
    WordPressImport.any_instance.expects(:add_page).times(1)
    
    assert @import.save
    assert @import.execute!('localhost', 'bill@bob.com')
  end
  
  def test_save_data
    ShopifyAPI::Article.any_instance.expects(:save).times(8)
    ShopifyAPI::Comment.any_instance.expects(:save).times(3)
    ShopifyAPI::Page.any_instance.expects(:save).times(2)
    ShopifyAPI::Blog.any_instance.expects(:save).times(1)
    
    assert @import.execute!('localhost', 'bill@bob.com')
    assert @import.save
  end
  
  def test_should_throw_exception_if_xml_is_invalid
    @import.content = '<?xml version="1.0" encoding="UTF-8"?> <wordpress> <<<stuff>'
    @import.save

    assert_raise REXML::ParseException do 
      @import.parse
    end
  end

  def test_should_add_default_email_to_comments_if_missing
    ShopifyAPI::Blog.any_instance.stubs(:new).returns({:comments_enabled => true, :title => 'blog_title'})
    
    @xml = <<-XML
      <wp:comment xmlns:wp='http://wordpress.org/export/1.0/'>
        <wp:comment_id>1</wp:comment_id>
        <wp:comment_author><![CDATA[Dan Philibin]]></wp:comment_author>
        <wp:comment_author_email></wp:comment_author_email>
        <wp:comment_author_url></wp:comment_author_url>
        <wp:comment_author_IP>207.255.235.40</wp:comment_author_IP>
        <wp:comment_date>2008-09-17 17:16:35</wp:comment_date>
        <wp:comment_date_gmt>2008-09-17 22:16:35</wp:comment_date_gmt>
        <wp:comment_content><![CDATA[Here is a non-admin comment.
   
        It has multiple lines, some <code>code</code>, and a bit more text.]]></wp:comment_content>
        <wp:comment_approved>1</wp:comment_approved>
        <wp:comment_type></wp:comment_type>
        <wp:comment_parent>0</wp:comment_parent>
        <wp:comment_user_id>0</wp:comment_user_id>
      </wp:comment>
    XML
    
    @import.send(:add_comments, [REXML::Document.new(@xml).elements[1]], ShopifyAPI::Article.new)
    
    comments = @import.send(:comments)
    assert !comments.keys.first.email.blank?
  end
end
