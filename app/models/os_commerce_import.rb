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

require 'csv'

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

class OsCommerceImport < Import

  validates_presence_of :base_url
  validates_presence_of  :content, :on => :create      # must have content just on creation of import

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
    # save each builder
    builders.each do |builder|
      if builder.save
        added('product')
      else
        self.import_errors << builder.errors
      end
    end

    rescue Exception => e
      RAILS_DEFAULT_LOGGER.debug "Exception: #{e.message}"
      RAILS_DEFAULT_LOGGER.debug "Backtrace: #{e.backtrace}"
      self.import_errors << "There was an error saving a product."
  end    

  private  

  # begin memoizations
  def possible_property_values
    @property_values ||= Hash.new
  end
  # end memoizations

  # helper methods
  def add_product(row)
    get_attributes(row)
    
    builders << ProductBuilder.new({ 
      :title => @title, 
      :body => @description, 
      :vendor => @vendor , 
      :product_type => @product_type || 'Blank', 
      :variants => add_variants(row),
      :images => add_product_image(@image_url),
      :collection => @collection_name
    })
  end
  
  def get_attributes(row)
    # product
    @title = row['v_products_name_1']
    @description = row['v_products_description_1']
    @vendor = if not row['v_manufacturers_name'].blank? then row['v_manufacturers_name'] else 'None' end
    @product_type = row['v_categories_name_1_1'] || row['v_categories_name_1']

    # image
    if Import.existent_url?("#{base_url}/images/#{row['v_products_image']}")
      @image_url = "#{base_url}/images/#{row['v_products_image']}"
    elsif Import.existent_url?("#{base_url}/images/#{row['v_products_image_med']}")
      @image_url = "#{base_url}/images/#{row['v_products_image_med']}"
    elsif Import.existent_url?("#{base_url}/images/#{row['v_products_image_lrg']}")
      @image_url = "#{base_url}/images/#{row['v_products_image_lrg']}"      
    else
      @image_url = ""
    end
    # because you never know...
 
    # collections
    @collection_name = if not row['v_categories_name_1'].blank? then row['v_categories_name_1'] else row['v_categories_name_1_1'] end    
  end 

  def add_product_image(url)
    return if url.blank? || !Import.existent_url?(url)
    
    ShopifyAPI::Image.new(:src => url)
  end
    
  def add_variants(row)
    if number_of_variants_for(row) <= 1
      create_default_variant(row)
      
    else # more than one variant
      # TODO: This could probably be optimized or at least compacted :)
      
      # get the actual existing properties
      actual_property_values = map_possibles_to_actuals(row)

      # set up the hash in order to map each property to all adjacent properties
      mapping_values = map_actuals_to_hash(row, actual_property_values)
      
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
      
      @variants = []
      0.upto(titles.size-1) do |index|
        @variants << create_variant(titles[index], @base_price.to_f + prices[index].to_f, @weight, @sku)
      end
      
      @variants
    end  
  end
        
  def create_default_variant(row)
    @title = 'Default'
    @price = row['v_products_price']
    @weight = row['v_products_weight']
    @sku = row['v_products_model']
    @quant = row['v_products_quantity']
    
    create_variant(@title, @price, @weight, @sku, @quant)
  end
  
  def create_variant(title, price, grams, sku, quant = nil)
    variant_attribs = { :title => title, :price => price, :grams => grams, :sku => sku }
    
    if quant
      variant_attribs[:inventory_management] = 'shopify'
      variant_attribs[:inventory_quantity] = quant
    end
    
    ShopifyAPI::Variant.new( variant_attribs )
  end
  
  def number_of_variants_for(product)
    counter = 0
    product.each do |header, value| 
      counter += 1 if header =~ /v_attribute_values_price/ && !value.blank?
    end
    counter
  end
  
  # this stores a Hash of all the possible combinations of variants (used in mapping multi-variants)
  def store_property_values(row)
    property_names = row.keys.join(" ").scan(/v_attribute_options_name_._1/)

    property_names.each do |property_name|
      property_name_number = property_name.scan(/v_attribute_options_name_(.)_1/).to_s
      possible_property_values[property_name] = row.keys.join(" ").scan(/v_attribute_values_name_#{property_name_number}_._1/)
    end            
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
  
  def map_possibles_to_actuals(row)
    actual_property_values = Hash.new
    possible_property_values.each do |property_name, property_values|
      property_name_number = property_name.scan(/v_attribute_options_name_(.)_1/).to_s

      property_values.each do |property_value|
        property_value_number = property_value.scan(/v_attribute_values_name_#{property_name_number}_(.)_1/).to_s
        if price = row["v_attribute_values_price_#{property_name_number}_#{property_value_number}"] and not price.blank?
          # we have a variant here
          actual_property_values["v_attribute_values_price_#{property_name_number}_#{property_value_number}"] = price
        end
      end
    end
    actual_property_values
  end
  
  def map_actuals_to_hash(row, actual_property_values)
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
    mapping_values
  end
  
end
