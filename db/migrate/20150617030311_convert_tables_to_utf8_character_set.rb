class ConvertTablesToUtf8CharacterSet < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.tables.each do |table_name|
      ActiveRecord::Base.connection.execute "ALTER TABLE #{table_name} CONVERT TO CHARACTER SET utf8"
    end
  end

  def down
    ActiveRecord::Base.connection.tables.each do |table_name|
      ActiveRecord::Base.connection.execute "ALTER TABLE #{table_name} CONVERT TO CHARACTER SET latin1"
    end
  end
end
