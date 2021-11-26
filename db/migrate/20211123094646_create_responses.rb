class CreateResponses < ActiveRecord::Migration[6.1]
  def change
    create_table :responses do |t|
      t.string :result
      t.string :status
      t.string :full_result
      t.string :token

      t.timestamps
    end
  end
end
