class OsCommerceImport < Import

  # Put it all together !
  def execute!
    if self.start_time.blank? # guard against executing the job multiple times
      self.start_time = Time.now
      self.parse
      self.save_data
      self.finish_time = Time.now
      self.save
    end
  end

  # from import.rb
  def source=(file_data)
    @file_data = file_data if file_data.original_filename.split(".").last == 'csv'
  end

  def skipped
  end

  def guess
  end

  def parse  
   csv_data = CSV.parse content
   headers = csv_data.shift.map {|i| i.to_s }
   row_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
   
   # map the csv headers to the cells of each row
   rows = row_data.map {|row| Hash[*headers.zip(row).flatten] }
   
   rows.each do |row|
     add_product(row)
   end
  end

  def save_data
    products.each(&:save)
  end

  private  
  
  def add_product(row)
    get_attributes(row)
    products << ShopifyAPI::Product.new( :title => @title, :body => @description, :vendor => @vendor, :product_type => @product_type )
  end
  
  def products
    @products ||= Array.new
  end  

  def get_attributes(row)
    @title = row['v_products_name_1']
    @description = row['v_products_description_1']
    @vendor = row['v_manufacturers_name']
    @product_type = row['v_categories_name_1_1']
  end 
  
end
