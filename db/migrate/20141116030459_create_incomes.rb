class CreateIncomes < ActiveRecord::Migration
  def self.up
    create_table :incomes do |t|
      t.string :description
      t.text :teamname
      t.text :playername1
      t.text :playername2
      t.timestamps
    end
  end

  def self.down
    drop_table :incomes
  end
end
