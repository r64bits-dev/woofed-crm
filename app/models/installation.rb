# == Schema Information
#
# Table name: installations
#
#  id         :string           not null, primary key
#  key1       :string           default(""), not null
#  key2       :string           default(""), not null
#  status     :integer          default("in_progress"), not null
#  token      :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  user_id    :bigint
#
# Indexes
#
#  index_installations_on_account_id  (account_id)
#  index_installations_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Installation < AccountRecord
  include Installation::Complete

  belongs_to :user, optional: true

  validates_presence_of :key1
  validates_presence_of :key2
  validates_presence_of :token

  before_validation :set_id, on: :create

  enum status: {
    in_progress: 0,
    completed: 1
  }
  def self.installation_url
    "https://store.woofedcrm.com/installations/new?installation_params=#{{ url: ENV.fetch('FRONTEND_URL', 'http://localhost:3001'),
                                                                           kind: :self_hosted }.to_json}"
  end

  def self.installation_flow?
    Installation.first&.status != 'completed'
  rescue StandardError
    true
  end

  private

  def set_id
    self.id ||= SecureRandom.uuid
  end
end
