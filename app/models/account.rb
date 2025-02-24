# == Schema Information
#
# Table name: accounts
#
#  id                  :bigint           not null, primary key
#  ai_usage            :jsonb            not null
#  name                :string           default(""), not null
#  number_of_employees :string           default("1-10"), not null
#  segment             :string           default("other"), not null
#  site_url            :string           default(""), not null
#  woofbot_auto_reply  :boolean          default(FALSE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class Account < ApplicationRecord
  validates :name, presence: true
  validates :name, length: { maximum: 255 }

  has_many :users, dependent: :destroy_async
  has_many :webhooks, dependent: :destroy_async
  has_many :stages, dependent: :destroy_async
  has_many :products, dependent: :destroy_async
  has_many :pipelines, dependent: :destroy_async
  has_many :events, dependent: :destroy_async
  has_many :deals, dependent: :destroy_async
  has_many :deal_products, dependent: :destroy_async
  has_many :custom_attribute_definitions, dependent: :destroy_async
  has_many :custom_attributes_definitions, class_name: 'CustomAttributeDefinition', dependent: :destroy_async
  has_many :contacts, dependent: :destroy_async
  has_many :apps_evolution_apis, dependent: :destroy_async, class_name: 'Apps::EvolutionApi'
  has_many :apps_chatwoots, dependent: :destroy_async, class_name: 'Apps::Chatwoot'
  has_many :apps, dependent: :destroy_async
  has_many :embedding_documments, dependent: :destroy_async
  has_many :attachments, dependent: :destroy_async

  enum segment: {
    technology: 'technology',
    health: 'health',
    finance: 'finance',
    education: 'education',
    retail: 'retail',
    services: 'services',
    manufacturing: 'manufacturing',
    telecommunications: 'telecommunications',
    transportation_logistics: 'transportation_logistics',
    real_estate: 'real_estate',
    energy: 'energy',
    agriculture: 'agriculture',
    tourism_hospitality: 'tourism_hospitality',
    entertainment_media: 'entertainment_media',
    construction: 'construction',
    public_sector: 'public_sector',
    consulting: 'consulting',
    startup: 'startup',
    ecommerce: 'ecommerce',
    security: 'security',
    automotive: 'automotive',
    other: 'other'
  }
  enum number_of_employees: {
    '1-10' => '1-10',
    '11-50' => '11-50',
    '51-200' => '51-200',
    '201-500' => '201-500',
    '501+' => '501+'
  }

  after_create :embed_company_site

  def site_url=(url)
    super(normalize_url(url))
  end

  def normalize_url(url)
    url = "https://#{url}" unless url.match?(%r{\Ahttp(s)?://})

    url
  end

  def embed_company_site
    Accounts::Create::EmbedCompanySiteJob.perform_later(id) if site_url.present? && ai_active?
  end

  def ai_active?
    ENV['OPENAI_API_KEY'].present?
  end

  def exceeded_account_limit?
    ai_usage['tokens'] >= ai_usage['limit']
  end
end
