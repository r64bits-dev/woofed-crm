class AddAccountIdToInstallations < ActiveRecord::Migration[6.1]
  def change
    add_reference :installations, :account, foreign_key: true

    reversible do |dir|
      dir.up do
        default_account = Account.first_or_create!(name: 'Default Account')
        Installation.update_all(account_id: default_account.id)
      end
    end

    change_column_null :installations, :account_id, false
  end
end
