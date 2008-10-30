class RenameSiteToShopUrl < ActiveRecord::Migration
  def self.up
    rename_column :imports, :site, :shop_url
  end

  def self.down
    rename_column :imports, :shop_url, :site
  end
end
