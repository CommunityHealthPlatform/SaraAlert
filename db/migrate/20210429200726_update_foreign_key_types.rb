class UpdateForeignKeyTypes < ActiveRecord::Migration[6.1]
  TABLE_COLUMNS = {
    users: %i[jurisdiction_id]
  }.freeze

  def up
    ActiveRecord::Base.record_timestamps = false
    change_column_type(TABLE_COLUMNS, :bigint)
    ActiveRecord::Base.record_timestamps = true
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    change_column_type(TABLE_COLUMNS, :integer)
    ActiveRecord::Base.record_timestamps = true
  end

  def change_column_type(table_columns, type)
    table_columns.each do |table, columns|
      columns.each do |column|
        change_column table, column, type
      end
    end
  end
end
