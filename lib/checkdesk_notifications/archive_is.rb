module CheckdeskNotifications
  module ArchiveIs
    def parse_parameters_for_archive_is_webhook(action, _settings = {})
      if action.to_s == 'create' && self.is_a?(ProjectMedia)
        data = { url: self.media.url }
        ['http://archive.is/submit/', data]
      else
        []
      end
    end

    def parse_response_from_archive_is_webhook(response)
      archived_url = nil

      if response['refresh']
        archived_url = response['refresh'].gsub(/^0;url=/, '')
      elsif response['location']
        archived_url = response['location']
      end

      unless archived_url.nil?
        media = self.media
        media.project_id = self.project_id
        comment = Comment.new
        comment.annotator = Bot.where(name: 'Check Bot').last
        comment.context = media.project unless media.project.nil?
        comment.text = "Archived to #{archived_url}"
        comment.annotated = self.media
        comment.save!
      end
    end
  end
end
