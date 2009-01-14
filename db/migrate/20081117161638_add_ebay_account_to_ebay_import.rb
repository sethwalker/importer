class AddEbayAccountToEbayImport < ActiveRecord::Migration
  def self.up
    add_column :imports, :ebay_account_id, :integer
  end

  def self.down
    remove_column :imports, :ebay_account_id 
  end
end
