module CheckdeskNotifications
  module Slack
    def parse_parameters_for_slack_webhook(action, settings = {})
      message_formatter = "format_slack_message_for_#{action}_#{self.class.name.underscore}"
      message = self.respond_to?(message_formatter) ? self.send(message_formatter) : ''
      if message.blank? || settings[:enabled].to_i != 1
        []
      else
        data = { payload: { channel: settings[:channel], text: message }.to_json }
        [settings[:webhook], data]
      end
    end

    def format_slack_message_for_create_project_media
      m = self.media
      data = m.data(self.project)
      type, text = data['quote'].blank? ? ['link', data['title']] : ['claim', data['quote']]
      "*#{m.user.name}* added a new #{type}: <#{m.origin}/project/#{m.project_id}/media/#{m.id}|*#{text}*>"
    end
  end
end
