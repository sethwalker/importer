class AddSiteColumnToImport < ActiveRecord::Migration
  def self.up
    add_column :imports, 'shop_url', :string
  end

  def self.down
    remove_column :imports, 'shop_url'
  end
end
