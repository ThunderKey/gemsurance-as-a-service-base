class Gaas::GemUsage < ApplicationRecord
  include Gaas::GemStatusSortable

  belongs_to :gem_version
  belongs_to :resource
  has_one :gem_info, through: :gem_version
  has_many :vulnerabilities, through: :gem_version

  validates :gem_version, uniqueness: {scope: :resource}

  validate do
    errors.add :in_gemfile, :blank if in_gemfile.nil?
  end

  delegate :gem_status, to: :gem_version
end
