class AddColumnsToImport < ActiveRecord::Migration
  def self.up
    add_column :imports, :base_url, :string
  end

  def self.down
    remove_column :imports, :base_url
  end
end
