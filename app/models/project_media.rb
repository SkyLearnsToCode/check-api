class ProjectMedia < ActiveRecord::Base
  attr_accessible

  belongs_to :project
  belongs_to :media
  belongs_to :user

  after_create :set_search_context, :set_initial_media_status
  
  notifies_webhooks proc { |pm| m = pm.media; m.current_team.blank? ? [] : m.current_team.setting(:subscriptions) }

  notifies_pusher on: :create,
                  event: 'media_updated',
                  targets: proc { |pm| [pm.project] },
                  data: proc { |pm| pm.media.to_json }

  def get_team
    p = self.project
    p.nil? ? [] : [p.team_id]
  end

  def media_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def project_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def set_initial_media_status
    st = Status.new
    st.annotated = self.media
    st.context = self.project
    st.annotator = self.user
    st.status = Status.default_id(self.media, self.project)
    st.created_at = self.created_at
    st.save!
  end

  private

  def set_search_context
    em_context = self.media.annotations('embed', self.project).last unless self.project.nil?
    if em_context.nil?
      em_none = self.media.annotations('embed', 'none').last
      unless em_none.nil?
        em_none.search_context << self.project.id
        em_none.save!
      end
    end
  end

end
