require 'csv'

class OsCommerceImport < Import

  # Put it all together !
  def execute!()
    if self.start_time.blank? # guard against executing the job multiple times
      self.type = 'OsCommerce'
      
      self.start_time = Time.now
      self.parse
      self.save_data
      self.finish_time = Time.now
      self.save
    end
  end

  # from import.rb
  def source=(file_data)
    @file_data = file_data #if file_data.original_filename.split(".").last == 'csv'
  end

  def skipped
  end

  def guess
  end
  
  def guessed(type)
    guesses = self.guesses || Hash.new
    guesses[type] += 1

    self.guesses = guesses.to_s
    self.save
  end

  def added(type)
    adds = self.adds || Hash.new
    adds[type] = (adds[type] || 0) + 1

    self.adds = adds.to_s
    self.save
  end

  def parse  
    
    if content.split("\n").first.include?(',')
      csv_data = CSV.parse(content)
    else # assuming tab delimited
      csv_data = CSV.parse(content.gsub(/"/, "&quot;"), "\t")
    end

    headers = csv_data.shift.map {|i| i.to_s }
    row_data = csv_data.map {|row| row.map {|cell| cell.to_s } }

    # map the csv headers to the cells of each row
    rows = row_data.map {|row| Hash[*headers.zip(row).flatten] }

    rows.each do |row|
     add_product(row)
    end
  end

  def save_data
    products.each do |product|
      if product.save
        # self.added('product')
        RAILS_DEFAULT_LOGGER.debug "Saving product #{product.title}...."
      end
    end
    
    product_images.each do |image, product|
      image.prefix_options[:product_id] = product.id
      if image.save
        RAILS_DEFAULT_LOGGER.debug "Saving image....#{image.src}"
        # self.added('image')
      end
    end

    variants.each do |variant, product|
      if default = ShopifyAPI::Product.find(product.id).attributes['variants'].find { |v| v.title == 'Default' }
        default.attributes.update(variant.attributes)
        variant = default
      end
      
      variant.prefix_options[:product_id] = product.id
  
      if variant.save
        # self.added('variant')
        RAILS_DEFAULT_LOGGER.debug "Saving variant....#{variant.title}"      
      end
    end
    
    collections.each do |collection|
      if collection.save
        # self.added('collection')
        RAILS_DEFAULT_LOGGER.debug "Saving collection....#{collection.title}"      
      end
    end
    
    collects.each do |collect|
      collect.product_id = collect.product_id.id
      collect.collection_id = collect.collection_id.id
      
      if collect.save
        # self.added('collect')
        RAILS_DEFAULT_LOGGER.debug "Saving collect....#{collect}"              
      end
    end
        
  end

  private  
  
  def products
    @products ||= Array.new
  end  

  def product_images
    @product_images ||= Hash.new
  end  
  
  def collections
    @collections ||= Array.new
  end
  
  def collects
    @collects ||= Array.new
  end
  
  def tags
    @tags ||= Array.new
  end
  
  def variants
    @variants ||= Hash.new
  end

  def add_product(row)
    get_product_attributes(row)
    products << product = ShopifyAPI::Product.new( :title => @title, :body => @description, :vendor => @vendor , :product_type => @product_type || 'Blank' )
    
    add_product_image(@image_url, product)
    add_variants(row, product)
    add_collection(@collection_name, product)
  end
  
  def get_product_attributes(row)
    # product
    @title = row['v_products_name_1']
    @description = row['v_products_description_1']
    @vendor = if not row['v_manufacturers_name'].blank? then row['v_manufacturers_name'] else 'None' end
    @product_type = row['v_categories_name_1_1'] || row['v_categories_name_1']

    # image
    @image_url = "#{base_url}/images/#{row['v_products_image']}"
        
    # collections
    @collection_name = if not row['v_categories_name_1'].blank? then row['v_categories_name_1'] else row['v_categories_name_1_1'] end
    
    # tags
    2.upto(7) do |num|
      tags << row["v_categories_name_#{num}_1"]
    end
  end 

  def add_product_image(url, product)
    image_path = URI.parse(url) rescue nil
    return if image_path.nil?
    
    product_images[ShopifyAPI::Image.new(:src => image_path)] = product  
  end
    
  def add_variants(row, product)
    if number_of_variants_for(row) <= 1
      create_default_variant(row, product)
    else # more than one variant
      
      # put each type of variant in an array
      # eg. [blue, red, green], [deluxe, standard], [4 mb, 6 mb, 8 mb]
      # Regexp.new(/v_attribute_values_price_(.*)_(.*)/).match(row)
      # @first = Regexp.last_match(1)
      # @last = Regexp.last_match(2)
      
      
      
      # recursively send each array to a map_2_arrays_method which will map each variant with each other variant
      # creates array1.size * array2.size * ... * arrayn.size variants
      # eg. above example 3 * 2 * 3 = 18 variants
      
      
    end  
  end
  
  def create_variant(row, heder, value, product)
    Regexp.new(/v_attribute_values_price_(.*)_(.*)/).match(header)
    @first = Regexp.last_match(1)
    @last = Regexp.last_match(2)
    @price = value
  
    @title = row["v_attribute_values_name_#{@first}_#{@last}_1"]
    @price = row['v_products_price'] + @price
    @weight = row['v_products_weight']
    @sku = row['v_products_model']  #### NEEDS COUNTER
    @os_commerce_property_name = row["v_attribute_options_name_#{@first}_1"]
  
    variants[ShopifyAPI::Variant.new( :title => @title, :price => @price, :grams => @weight, :sku => @sku, :property_name => @os_commerce_property_name )] = product
  end
  
  def create_default_variant(row, product)
    @title = 'Default'
    @price = row['v_products_price']
    @weight = row['v_products_weight']
    @sku = row['v_products_model']

    variants[ShopifyAPI::Variant.new( :title => @title, :price => @price, :grams => @weight, :sku => @sku )] = product
  end
  
  def map_variants_for(product)
    variants.each do |variant, current_product|
      if product == current_product
        
      end
    end
  end
  
  def number_of_variants_for(product)
    counter = 0
    product.each do |header, value| 
      counter += 1 if header =~ /v_attribute_values_price/ && !value.blank?
    end
    counter
  end
  
  def add_collection(collection_name, product)
    collection = collections.find { |c| c.title == collection_name }

    if not collection
      collections << collection = ShopifyAPI::CustomCollection.new( :title => collection_name )      
    end
    
    collects << ShopifyAPI::Collect.new(:collection_id => collection, :product_id => product)
  end
  
end
