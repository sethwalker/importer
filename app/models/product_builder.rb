class ProductBuilder

  attr_reader :product, :variants, :images, :collection

  def initialize(attributes = nil)
    load(attributes)
  end

  def errors
    [(product.errors.full_messages rescue []) + variants.collect(&:errors).collect(&:full_messages) + images.collect(&:errors).collect(&:full_messages) + (collection.errors.full_messages rescue [])].flatten 
  end

  def product=(product)
    load(product)
  end

  def add_variant(variant)
    @variants << load_variant(variant)
  end

  def add_image(image)
    @images << load_image(image)
  end

  def find_or_save_collection
    raise self.inspect unless collection && !collection.nil?
    @@collections ||= {}
    @@collections[collection.title] ||= ShopifyAPI::CustomCollection.find(:all).find { |c| c.title == collection.title }
    @@collections[collection.title] ||= collection.save
    return @@collections[collection.title]
  rescue Exception => c
    raise self.inspect
  end

  def save
    return false unless valid?

    begin
      product.save
      
      variants.each do |variant|
        if default = ShopifyAPI::Product.find(product.id).attributes['variants'].find { |v| v.title == 'Default' }
          default.attributes.update(variant.attributes)
          variant = default
        end
        
        variant.prefix_options[:product_id] = product.id
        variant.save
      end

      images.each do |image|
        if Import.existent_url?(image.src.to_s)
          image.prefix_options[:product_id] = product.id
          image.save
        end
      end
      
      if collection.title != nil 
        collection = find_or_save_collection

        ShopifyAPI::Collect.create( :collection_id => collection.id, :product_id => product.id )
      end

      true      
    rescue ActiveResource::ResourceNotFound => e
      # import_errors << "Error importing your shop. Some data could not be saved."
      false
    rescue ActiveResource::ServerError => e
      # import_errors << "Error importing your shop. Some data could not be saved."
      false
    rescue ActiveResource::ClientError => e
      # import_errors << "So far, you have imported #{adds['product'] || 0} products. This seems to be the maximum number of allowed products for your subscription plan. Please <a href='http://#{shop_url}/admin/accounts/'>upgrade your subscription</a> to allow for more products."
      false
    end
  end

  def save!
    save || raise(ActiveResource::ResourceNotFound, "Validation failed: #{errors.to_sentence}")
  end

  def valid?
    return false if product.nil?

    product.valid? && variants.all?(&:valid?) && images.all?(&:valid?) && collection.valid?
  end

  private

  def update_variants(variants_attributes)
    return variants if variants_attributes.nil?

    variants_attributes.collect do |attributes|
      variant = variants.find{|v| v.id == attributes[:id]} || product.variants.build
      variant.attributes = attributes
      variant
    end
  end

  def update_images(images_attributes)
    return images if images_attributes.nil?

    images_attributes.collect do |attributes|
      images.find{|v| v.id == attributes[:id]} || product.images.build(attributes)
    end
  end

  def load_product(attributes)
    attributes.is_a?(ShopifyAPI::Product) ? attributes : @product = ShopifyAPI::Product.new(attributes.except(:variants, :images))
  end

  def load_variants(attributes)
    attributes = attributes.is_a?(ShopifyAPI::Product) ? attributes.variants : attributes[:variants]

    return [ ] if attributes.blank?

    [attributes].flatten.collect do |variant|
      load_variant(variant)
    end    
  end

  def load_variant(attributes)
    attributes.is_a?(ShopifyAPI::Variant) ? attributes : @variants << ShopifyAPI::Variant.new(attributes)
  end

  def load_images(attributes)
    attributes = attributes.is_a?(ShopifyAPI::Product) ? attributes.images : attributes[:images]

    return [] if attributes.blank?

    [attributes].flatten.collect do |image|
      load_image(image)
    end
  end

  def load_image(attributes)
    if attributes.is_a?(ShopifyAPI::Image)
      attributes
    else
      nil
    end
    
  end
  
  def load_collection(attributes)
    @collection = ShopifyAPI::CustomCollection.new( :title => attributes[:collection] )
  end

  def load(attributes)
    if attributes
      @product    = load_product(attributes)
      @variants   = load_variants(attributes)
      @images     = load_images(attributes)
      @collection = load_collection(attributes)
      
      @images = [] if @images == [nil]

    else
      @product    = nil
      @variants   = []
      @images     = []
      @collection = nil
    end
  end

  def logger
    Rails.logger
  end
end
