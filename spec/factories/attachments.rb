# == Schema Information
#
# Table name: attachments
#
#  id              :bigint           not null, primary key
#  attachable_type :string           not null
#  file_type       :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  attachable_id   :bigint           not null
#
# Indexes
#
#  index_attachments_on_account_id  (account_id)
#  index_attachments_on_attachable  (attachable_type,attachable_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
FactoryBot.define do
  factory :attachment do
    trait :for_product do
      transient do
        account { nil }
      end

      after(:build) do |attachment, evaluator|
        product = create(:product, account: evaluator.account)
        attachment.attachable = product
      end
    end

    trait :image do
      file_type { 'image' }
      file { Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/files/patrick.png") }
    end
  end
end
