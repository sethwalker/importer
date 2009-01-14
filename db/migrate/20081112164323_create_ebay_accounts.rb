class CreateEbayAccounts < ActiveRecord::Migration
  def self.up
    create_table :ebay_accounts do |t|
      t.column :name,             :string
      t.column :ebay_id,          :string
      t.column :ebay_site_id,     :integer
      t.column :paypal_account,   :string
      t.column :ebay_token,       :text
      t.column :ebay_token_expiry,:string
      t.column :shop,             :string
      t.column :country,          :string
      t.column :city,             :string
      t.column :province,         :string
      t.column :time_zone,        :string
      t.column :currency,         :string, :default => "USD"
      
      
      t.timestamps
    end
  end

  def self.down
    drop_table :ebay_accounts
  end
end
