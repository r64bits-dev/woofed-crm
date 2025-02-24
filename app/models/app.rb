# == Schema Information
#
# Table name: apps
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(FALSE), not null
#  kind       :string
#  name       :string
#  settings   :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_apps_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class App < AccountRecord
  enum kind: { 'wpp_connect': 'wpp_connect' }
end
