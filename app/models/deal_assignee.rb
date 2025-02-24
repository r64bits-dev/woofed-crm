# == Schema Information
#
# Table name: deal_assignees
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deal_id    :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_deal_assignees_on_deal_id              (deal_id)
#  index_deal_assignees_on_deal_id_and_user_id  (deal_id,user_id) UNIQUE
#  index_deal_assignees_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (deal_id => deals.id)
#  fk_rails_...  (user_id => users.id)
#
class DealAssignee < ApplicationRecord
  belongs_to :deal
  belongs_to :user

  delegate :account, to: :deal

  validates :user_id, uniqueness: { scope: :deal_id, message: :taken }
end
