class AddContentColumnToImportsTable < ActiveRecord::Migration
  def self.up
    add_column :imports, 'content', :text, :limit => 2147483647
  end

  def self.down
    remove_column :imports, 'content'
  end
end
