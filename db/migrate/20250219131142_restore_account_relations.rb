class RestoreAccountRelations < ActiveRecord::Migration[6.1]
  def change
    add_reference :users, :account, foreign_key: true
    add_reference :webhooks, :account, foreign_key: true
    add_reference :stages, :account, foreign_key: true
    add_reference :products, :account, foreign_key: true
    add_reference :pipelines, :account, foreign_key: true
    add_reference :events, :account, foreign_key: true
    add_reference :deals, :account, foreign_key: true
    add_reference :deal_products, :account, foreign_key: true
    add_reference :custom_attribute_definitions, :account, foreign_key: true
    add_reference :contacts, :account, foreign_key: true
    add_reference :apps_evolution_apis, :account, foreign_key: true
    add_reference :apps_chatwoots, :account, foreign_key: true
    add_reference :apps, :account, foreign_key: true
    add_reference :embedding_documments, :account, foreign_key: true

    reversible do |dir|
      dir.up do
        default_account = Account.first_or_create!(name: 'Default Account')
        
        User.update_all(account_id: default_account.id)
        Webhook.update_all(account_id: default_account.id)
        Stage.update_all(account_id: default_account.id)
        Product.update_all(account_id: default_account.id)
        Pipeline.update_all(account_id: default_account.id)
        Event.update_all(account_id: default_account.id)
        Deal.update_all(account_id: default_account.id)
        DealProduct.update_all(account_id: default_account.id)
        CustomAttributeDefinition.update_all(account_id: default_account.id)
        Contact.update_all(account_id: default_account.id)
        Apps::EvolutionApi.update_all(account_id: default_account.id)
        Apps::Chatwoot.update_all(account_id: default_account.id)
        App.update_all(account_id: default_account.id)
        EmbeddingDocumment.update_all(account_id: default_account.id)
      end
    end

    change_column_null :users, :account_id, false
    change_column_null :webhooks, :account_id, false
    change_column_null :stages, :account_id, false
    change_column_null :products, :account_id, false
    change_column_null :pipelines, :account_id, false
    change_column_null :events, :account_id, false
    change_column_null :deals, :account_id, false
    change_column_null :deal_products, :account_id, false
    change_column_null :custom_attribute_definitions, :account_id, false
    change_column_null :contacts, :account_id, false
    change_column_null :apps_evolution_apis, :account_id, false
    change_column_null :apps_chatwoots, :account_id, false
    change_column_null :apps, :account_id, false
    change_column_null :embedding_documments, :account_id, false
  end
end
