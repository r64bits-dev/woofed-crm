# == Schema Information
#
# Table name: embedding_documments
#
#  id               :bigint           not null, primary key
#  content          :text
#  embedding        :vector(1536)
#  source_reference :string
#  source_type      :string
#  status           :integer          default(0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  source_id        :bigint
#
# Indexes
#
#  index_embedding_documments_on_account_id  (account_id)
#  index_embedding_documments_on_source      (source_type,source_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
FactoryBot.define do
  factory :embedding_documment do
  end
end
