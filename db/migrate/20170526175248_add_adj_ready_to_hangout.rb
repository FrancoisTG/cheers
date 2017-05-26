class AddAdjReadyToHangout < ActiveRecord::Migration[5.0]
  def change
    add_column :hangouts, :adj_ready, :boolean, null: false, default: false
  end
end
