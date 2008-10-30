require 'csv'
require 'uri'
require 'net/http'

# From: http://www.rubyonrailsblog.com/articles/2006/08/31/permutations-in-ruby-can-be-fun (in the comments)
# Author: Brian Mitchell
class Array
  # The accumulation is a bit messy but it works ;-)
  def sequence(i = 0, *a)
    return [a] if i == size
    self[i].map {|x|
      sequence(i+1, *(a + [x]))
    }.inject([]) {|m, x| m + x}     # this has to be used instead of flatten so I can sequence something
                                    # like [[[4]]] -> [[[4]]] rather than -> [[4]]; ruby 1.9 has an option for flatten
  end
end

class Mailer < ActionMailer::Base
  def log(url, recipient, message)
    from       ENV['from_address']
    recipients recipient
    subject    "[#{url}] Batch import completed"
    body       "Importer successfully completed your import. \n\n#{message}"
  end
end

class OsCommerceImport < Import

  # Put it all together !
  def execute!(site, email_recipient)
    ShopifyAPI::CustomCollection.find(:all).each { |c| c.destroy }
    if self.start_time.blank? # guard against executing the job multiple times
    
      # initialize
      ShopifyAPI::Product.superclass.site = site # this is for DJ, it can't seem to find the site at execution time unless
      RAILS_DEFAULT_LOGGER.debug "site is #{ShopifyAPI::Product.superclass.site}"
      self.type = 'OsCommerce'
      self.start_time = Time.now
    
      # parse data
      begin
        self.parse
      rescue NameError => e
       errors << "There was an error parsing your import file."
      rescue CSV::IllegalFormatError => e
        errors << "There was an error parsing your import file. Your import file is not a valid CSV file."      
      end
    
      # save data
      begin
        self.save_data
      rescue ActiveResource::ResourceNotFound => e
        errors << "Error importing your shop. Some data could not be saved."
      rescue ActiveResource::ServerError => e
        errors << "Error importing your shop. Some data could not be saved."
      rescue ActiveResource::ClientError => e
        errors << "So far, you have imported #{adds['product']} products. This seems to be the maximum number of allowed products for your subscription plan. Please <a href='http://#{site}/admin/accounts/'>upgrade your subscription</a> to allow for more products."
      end
      
      # wrap it up
      self.finish_time = Time.now
      self.save
      
      # email
      message = ""
      adds.each { |key,value| message += "#{value} #{key}s successfully imported.\n"}
      message += "\n"
      adds.keys.each { |key| message += "#{skipped(key)} #{key}s skipped.\n"}

      Mailer.deliver_log(base_url, email_recipient, message)
    end
  end

  def skipped(type)
    guesses[type].to_i - adds[type].to_i
  end

  def guess
    rows = parse_content(content)
    
    rows.each_with_index do |row, index|
      store_property_values(row) if index == 0
      guessed('product')
    end
  end
  
  def parse  
    rows = parse_content(content)
    
    rows.each_with_index do |row, index|
      store_property_values(row) if index == 0
      add_product(row)
    end
  end

  def save_data
    save_products
    save_images
    save_variants
    save_collections
    save_collects
  end
  
  # save methods
  def save_products
    products.each do |product|
      if product.save
        RAILS_DEFAULT_LOGGER.debug "Saving product #{product.title}...."
        added('product')
      end
    end
  end
    
  def save_images
    product_images.each do |image, product|
      image.prefix_options[:product_id] = product.id

      if OsCommerceImport.existent_url?(image.src.to_s) and image.save
        RAILS_DEFAULT_LOGGER.debug "Saving image....#{image.src}"
        added('image')
      end
    end
  end

  def save_variants
    variants.each do |variant, product|
      if default = ShopifyAPI::Product.find(product.id).attributes['variants'].find { |v| v.title == 'Default' }
        default.attributes.update(variant.attributes)
        variant = default
      end
      
      variant.prefix_options[:product_id] = product.id
  
      if variant.save
        RAILS_DEFAULT_LOGGER.debug "Saving variant....#{variant.title}"      
        added('variant')
      end
    end
  end
    
  def save_collections
    collections.each do |collection|
      if collection.save
        RAILS_DEFAULT_LOGGER.debug "Saving collection....#{collection.title}"      
        added('collection')
      end
    end
  end
  
  def save_collects
    collects.each do |collect|
      collect.product_id = collect.product_id.id
      collect.collection_id = collect.collection_id.id
      
      if collect.save
        RAILS_DEFAULT_LOGGER.debug "Saving collect....#{collect}"              
        added('collect')
      end
    end
  end

  private  

  # begin memoizations
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
  
  # def tags
  #   @tags ||= Array.new
  # end
  
  def variants
    @variants ||= Hash.new
  end
  
  def possible_property_values
    @property_values ||= Hash.new
  end
  # end memoizations

  # helper methods
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
    if not OsCommerceImport.existent_url?(@image_url)
      @image_url = "#{base_url}/catalog/images/#{row['v_products_image']}" #try this...
      if not OsCommerceImport.existent_url?(@image_url)
        @image_url = ""
      end
    end
 
    # collections
    @collection_name = if not row['v_categories_name_1'].blank? then row['v_categories_name_1'] else row['v_categories_name_1_1'] end
    
    # tags
    # 2.upto(7) do |num|
    #   tags << row["v_categories_name_#{num}_1"]
    # end
  end 

  def add_product_image(url, product)
    return if url.blank?
    
    product_images[ShopifyAPI::Image.new(:src => url)] = product  
  end
    
  def add_variants(row, product)
    if number_of_variants_for(row) <= 1
      create_default_variant(row, product)
    else # more than one variant
      actual_property_values = Hash.new
      
      possible_property_values.each do |property_name, property_values|
        property_name_number = property_name.scan(/v_attribute_options_name_(.)_1/).to_s

        property_values.each do |property_value|
          property_value_number = property_value.scan(/v_attribute_values_name_#{property_name_number}_(.)_1/).to_s
          if price = row["v_attribute_values_price_#{property_name_number}_#{property_value_number}"] and not price.blank?
            # we have a variant
            actual_property_values["v_attribute_values_price_#{property_name_number}_#{property_value_number}"] = price
          end
        end
      end
      
      mapping_values = Hash.new
      # set up the proper hash for mapping
      possible_property_values.each do |property_name, property_values|
        property_name_number = property_name.scan(/v_attribute_options_name_(.)_1/).to_s

        current_matches = actual_property_values.keys.join(" ").scan(/v_attribute_values_price_#{property_name_number}_./)
        
        current_matches.each do |match|
          property_value_number = match.scan(/v_attribute_values_price_#{property_name_number}_(.)/).to_s
          current_title = row["v_attribute_values_name_#{property_name_number}_#{property_value_number}_1"]
          current_price = actual_property_values["v_attribute_values_price_#{property_name_number}_#{property_value_number}"]
          
          if not mapping_values[property_name_number]
            mapping_values[property_name_number] = Hash.new
          end
          
          mapping_values[property_name_number].update( { current_title => current_price } )
          
        end
      end
      
      # DO the mapping
      titles = Array.new
      prices = Array.new
      mapping_values.values.map(&:keys).sequence.each do |arr|
        titles << arr.join(" ")
      end
      
      mapping_values.values.map(&:values).sequence.each do |arr|
        if arr.size == 1
          prices << arr.first.to_f
        else
          prices << arr.inject {|sum, n| sum.to_f + n.to_f }
        end
      end   
      
      @weight = row['v_products_weight']
      @sku = row['v_products_model']
      @base_price = row['v_products_price']
      
      0.upto(titles.size-1) do |index|
        create_variant(titles[index], @base_price.to_f + prices[index], @weight, @sku, product)
      end
      
    end  
  end
        
  def create_default_variant(row, product)
    @title = 'Default'
    @price = row['v_products_price']
    @weight = row['v_products_weight']
    @sku = row['v_products_model']
    
    create_variant(@title, @price, @weight, @sku, product)
  end
  
  def create_variant(title, price, grams, sku, product)
    variants[ShopifyAPI::Variant.new( :title => title, :price => price, :grams => grams, :sku => sku )] = product
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
  
  def store_property_values(row)
    property_names = row.keys.join(" ").scan(/v_attribute_options_name_._1/)

    property_names.each do |property_name|
      property_name_number = property_name.scan(/v_attribute_options_name_(.)_1/).to_s
      possible_property_values[property_name] = row.keys.join(" ").scan(/v_attribute_values_name_#{property_name_number}_._1/)
    end            
  end
  
  def self.existent_url?(url)
    uri = URI.parse(url)
    http_conn = Net::HTTP.new(uri.host, uri.port)
    resp, data = http_conn.head(uri.path , nil)
    resp.code == "200"
  end
  
  def parse_content(content)
    if content.split("\n").first.include?(',')
      csv_data = CSV.parse(content)
    else # assuming tab delimited
      csv_data = CSV.parse(content.gsub(/"/, "&quot;"), "\t")
    end

    headers = csv_data.shift.map {|i| i.to_s }
    row_data = csv_data.map {|row| row.map {|cell| cell.to_s } }

    # map the csv headers to the cells of each row
    rows = row_data.map {|row| Hash[*headers.zip(row).flatten] }
  end
  
end
