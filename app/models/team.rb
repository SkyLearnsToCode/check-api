class Team < ActiveRecord::Base
  attr_accessible
  has_paper_trail on: [:create, :update]
  has_many :projects
  has_many :accounts
  has_many :team_users
  has_many :users, through: :team_users
  has_many :contacts

  mount_uploader :logo, ImageUploader

  validates_presence_of :name
  validates_presence_of :subdomain
  validates_format_of :subdomain, :with => /\A[[:alnum:]-]+\z/, :message => 'accepts only letters, numbers and hyphens'
  validates :subdomain, length: { in: 4..63 }
  validates :subdomain, uniqueness: true
  validates :logo, size: true

  after_create :add_user_to_team

  has_annotations

  def set_creator_as_team_owner
    tu = TeamUser.new
    tu.user = current_user
    tu.team = self
    tu.role = 'owner'
    tu.save!
  end

  def logo_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  private

  def add_user_to_team
    unless self.current_user.nil?
      tu = TeamUser.new
      tu.user = self.current_user
      tu.team = self
      tu.save!
    end
  end

  def self.subdomain_from_name(name)
    name.parameterize.underscore.dasherize.ljust(4, '-')
  end

end
