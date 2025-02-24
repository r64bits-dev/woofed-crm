# == Schema Information
#
# Table name: deal_products
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  deal_id    :bigint           not null
#  product_id :bigint           not null
#
# Indexes
#
#  index_deal_products_on_account_id  (account_id)
#  index_deal_products_on_deal_id     (deal_id)
#  index_deal_products_on_product_id  (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (deal_id => deals.id)
#  fk_rails_...  (product_id => products.id)
#
class DealProduct < AccountRecord
  include DealProduct::Broadcastable
  include DealProduct::EventCreator

  belongs_to :product
  belongs_to :deal
  belongs_to :account
end
