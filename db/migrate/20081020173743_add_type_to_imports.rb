class AddTypeToImports < ActiveRecord::Migration
  def self.up
    add_column :imports, :type, :string
  end

  def self.down
    remove_column :imports, :type
  end
end
