class AddSlugToHangouts < ActiveRecord::Migration[5.0]
  def change
    add_column :hangouts, :slug, :string, index: { unique: true}
  end
end
