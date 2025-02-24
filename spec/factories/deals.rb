# == Schema Information
#
# Table name: deals
#
#  id                :bigint           not null, primary key
#  custom_attributes :jsonb
#  name              :string           default(""), not null
#  position          :integer          default(1), not null
#  status            :string           default("open"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  contact_id        :bigint           not null
#  created_by_id     :integer
#  pipeline_id       :bigint
#  stage_id          :bigint           not null
#
# Indexes
#
#  index_deals_on_account_id     (account_id)
#  index_deals_on_contact_id     (contact_id)
#  index_deals_on_created_by_id  (created_by_id)
#  index_deals_on_pipeline_id    (pipeline_id)
#  index_deals_on_stage_id       (stage_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (stage_id => stages.id)
#
FactoryBot.define do
  factory :deal do
    account
    stage
    contact
    name { 'Deal 1' }

    after(:build) do |deal|
      # Ensure stage belongs to the same account
      if deal.stage && deal.stage.account_id != deal.account_id
        deal.stage.update!(account_id: deal.account_id)
      end

      # Ensure contact belongs to the same account
      if deal.contact && deal.contact.account_id != deal.account_id
        deal.contact.update!(account_id: deal.account_id)
      end
    end
  end
end
