class AddSiteColumnToImport < ActiveRecord::Migration
  def self.up
    add_column :imports, 'site', :string
  end

  def self.down
    remove_column :imports, 'site'
  end
end
