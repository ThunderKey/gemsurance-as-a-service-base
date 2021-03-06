class Gaas::Resource < ApplicationRecord
  include Gaas::GemStatusSortable

  enum resource_type: Hash[Gaas::GemsuranceService.fetchers.keys.map {|name| [name, name] }]
  enum fetch_status: Hash[[:pending, :successful, :failed].map {|k| [k, k.to_s] }]

  has_many :gem_usages, dependent: :destroy
  has_many :gem_versions, through: :gem_usages
  has_many :gem_infos, through: :gem_versions
  has_many :vulnerabilities, through: :gem_versions

  validates :name, presence: true, uniqueness: true
  validates :path, presence: true, format: {with: GaasHelper.absolute_path_regex, message: :relative_path}
  validates :resource_type, presence: true
  validates :build_image_url, format: {with: Gaas.config.url_regex, message: :invalid_url, allow_blank: true}
  validates :build_url, format: {with: Gaas.config.url_regex, message: :invalid_url, allow_blank: true}

  validate do
    if resource_type
      gemsurance_service.errors.each {|k,m| errors.add k, m }
    end
  end

  before_save do
    self.fetch_status ||= :pending
    self.fetch_output ||= ''
  end

  after_create do
    start_update!
  end

  def self.resource_type_attributes_for_select
    resource_types.keys.map do |resource_type|
      [I18n.t("activerecord.attributes.#{model_name.i18n_key}.resource_types.#{resource_type}"), resource_type]
    end
  end

  def gem_status
    if vulnerabilities.any?
      :vulnerable
    else
      :current
    end
  end

  def outdated_gem_versions
    gem_versions.select(&:outdated?)
  end

  def gemsurance_service
    @gemsurance_service ||= Gaas::GemsuranceService.new self
  end

  def start_update!
    self.fetch_status = :pending
    save!
    Gaas::UpdateResourceJob.perform_later id
  end
end
