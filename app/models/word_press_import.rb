class WordPressImport < Import

  def blog_title
    @blog_title ||= REXML::XPath.match(xml, 'rss/channel/title').first.text    
  end
  
  def original_url
    @original_url ||= REXML::XPath.match(xml, 'rss/channel/link').first.text
  end
  
  def skipped
    (self.posts_guess + self.pages_guess + self.comments_guess) - (self.posts + self.pages + self.comments)
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
        self.guessed('post') if status == 'publish' || status == 'draft'
        comments.each { |c| self.guessed('comment') }
      end      
    end
  end
    
  def parse
    # Start timing!
    self.start_time = Time.now
    
    # Create a new blog with the title from Wordpress
    @blog = ShopifyAPI::Blog.new(:title => blog_title)   

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
    pages.each(&:save)

    @blog.save
    articles.each do |a|
      a.prefix_options[:blog_id] = @blog.id
      a.save
    end

    # comments is a hash of [ShopifyAPI::Comment => ShopifyAPI::Article]
    comments.each do |key, value|
      key.blog_id = @blog.id
      key.article_id = value.id
      key.save
    end
    
    # Stop timing!
    self.finish_time = Time.now
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
  
  def add_page(node)
    get_attributes(node)    
    pages << ShopifyAPI::Page.new( :title => @title, :body => @body, :author => @author, :published_at => @pub_date )

    self.added('page')
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

    self.added('post')   
    
    add_comments(node.elements.select {|e| e.name == "comment" } , article)
  end
  
  def add_comments(nodes, article)
    @blog.commentable = 'yes' unless @blog.comments_enabled?
    
    nodes.each do |comment_node|
      # We have to add a prefix from the root node so that REXML is happy
      comment_string = comment_node.to_s.gsub('<wp:comment>', "<wp:comment xmlns:wp='http://wordpress.org/export/1.0/'>")

      # New XML doc starting at the root of the comment
      @comment_root_node = REXML::Document.new(comment_string).elements[1]

      author = @comment_root_node.elements.select { |e| e.name == "comment_author" }.first.text
      email = @comment_root_node.elements.select { |e| e.name == "comment_author_email" }.first.text
      body = @comment_root_node.elements.select { |e| e.name == "comment_content" }.first.text
      pub_date = @comment_root_node.elements.select { |e| e.name == "comment_date" }.first.text

      comments[ShopifyAPI::Comment.new( :body => body, :author => author, :email => email, :published_at => pub_date )] = article

      self.added('comment')
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
