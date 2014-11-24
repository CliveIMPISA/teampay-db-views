class CreateIncomes < ActiveRecord::Migration
  def self.up
    create_table :incomes do |t|
      t.string :description
      t.text :teamnames
      t.text :player_names
      t.text :player_names2
      t.timestamps
    end
  end

  def self.down
    drop_table :incomes    
  end
end
