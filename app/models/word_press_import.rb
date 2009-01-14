# == Schema Information
# Schema version: 20081117161638
#
# Table name: imports
#
#  id              :integer(11)     not null, primary key
#  created_at      :datetime
#  updated_at      :datetime
#  content         :text(2147483647
#  start_time      :datetime
#  finish_time     :datetime
#  shop_url        :string(255)
#  adds            :text
#  guesses         :text
#  type            :string(255)
#  base_url        :string(255)
#  submitted_at    :datetime
#  import_errors   :text
#  ebay_account_id :integer(11)
#

class WordPressImport < Import
  
  validates_presence_of  :content, :on => :create      # must have content just on creation of import

  def blog_title
    @blog_title ||= REXML::XPath.match(xml, 'rss/channel/title').first.text    
  end
  
  def original_url
    @original_url ||= REXML::XPath.match(xml, 'rss/channel/link').first.text
  end
    
  def guess
    # Loop through each <item> tag in the file
    REXML::XPath.match(xml, 'rss/channel/item').each do |node|
      status = node.elements.select {|e| e.name == "status" }.first.text
      comments = node.elements.select {|e| e.name == "comment" }
      
      case node.elements.find {|e| e.name == "post_type" }.text
      when 'page'
        self.guessed('page')
      when 'post'
        self.guessed('article') if status == 'publish' || status == 'draft'
        comments.each { |c| self.guessed('comment') }
      end      
    end
    
  rescue REXML::ParseException => e
    self.import_errors << e.message
  end
    
  def parse
    # Loop through each <item> tag in the file
    REXML::XPath.match(xml, 'rss/channel/item').each do |node|
      case node.elements.find {|e| e.name == "post_type" }.text
      when 'page'
        add_page(node)
      when 'post'
        add_article(node)        
      end      
    end
  end
  
  def save_data
    pages.each do |p|
      current_saved_date = p.published_at
      p.save
      
      p.published_at = current_saved_date
      if p.save
        added('page')
      end
    end

    blog.save    
    articles.each do |a|  
      current_saved_date = a.published_at
      a.prefix_options[:blog_id] = blog.id
      a.save
      
      a.published_at = current_saved_date
      if a.save
        added('article')
      end
    end
    
    # comments is a hash of [ShopifyAPI::Comment => ShopifyAPI::Article]
    comments.each do |comment, article|
      comment.blog_id = blog.id
      comment.article_id = article.id
      if comment.save
        added('comment')
      end
    end
  end
  
  private  
  def xml
    @xml ||= REXML::Document.new(self.content)    
  end
  
  def pages
    @pages ||= Array.new
  end

  def articles
    @articles ||= Array.new
  end

  def comments
    @comments ||= Hash.new
  end
  
  def blog
    @blog ||= ShopifyAPI::Blog.new(:title => blog_title)
  end
  
  def add_page(node)
    get_attributes(node)    
    pages << ShopifyAPI::Page.new( :title => @title, :body => @body, :author => @author, :published_at => @pub_date )
  end
  
  def add_article(node)
    get_attributes(node)
    
    if @status == 'publish'
      article = ShopifyAPI::Article.new( :title => @title, :body => @body, :author => @author, :published_at => @pub_date )
      articles << article
    elsif @status == 'draft'
      article = ShopifyAPI::Article.new( :title => @title, :body => @body, :author => @author, :published_at => 0 )
      articles << article
    end
    
    add_comments(node.elements.select {|e| e.name == "comment" } , article)
  end
  
  def add_comments(nodes, article)
    blog.commentable = 'yes' unless blog.comments_enabled?
    
    nodes.each do |comment_node|
      # We have to add a prefix from the root node so that REXML is happy
      comment_string = comment_node.to_s.gsub('<wp:comment>', "<wp:comment xmlns:wp='http://wordpress.org/export/1.0/'>")

      # New XML doc starting at the root of the comment
      @comment_root_node = REXML::Document.new(comment_string).elements[1]

      author = @comment_root_node.elements.select { |e| e.name == "comment_author" }.first.text
      email = @comment_root_node.elements.select { |e| e.name == "comment_author_email" }.first.text
      body = @comment_root_node.elements.select { |e| e.name == "comment_content" }.first.text
      pub_date = @comment_root_node.elements.select { |e| e.name == "comment_date" }.first.text
      
      email = 'blank@blank.com' if email.blank?

      comments[ShopifyAPI::Comment.new( :body => body, :author => author, :email => email, :published_at => pub_date )] = article
    end    
  end
  
  def get_attributes(node)
    @status = node.elements.select {|e| e.name == "status" }.first.text
    @title = node.elements["title"].text
    @body = node.elements.select {|e| e.name == "encoded" }.first.text
    @pub_date = DateTime.parse(node.elements.find {|e| e.name == "post_date" }.text).strftime('%F %T') if @status == 'publish'
    @author = node.elements.find {|e| e.name == "creator" }.text
  end
end
