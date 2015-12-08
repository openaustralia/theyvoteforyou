class ConvertTablesToUnicodeCollation < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.tables.each do |table_name|
      ActiveRecord::Base.connection.execute "ALTER TABLE #{table_name} CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci"
    end
  end

  def down
    ActiveRecord::Base.connection.tables.each do |table_name|
      ActiveRecord::Base.connection.execute "ALTER TABLE #{table_name} CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci"
    end
  end
end
