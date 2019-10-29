class AddFailedLogins < ActiveRecord::Migration
  def change
    add_column :users, :failed_logins, :integer, null: false, default: 0
  end
end
