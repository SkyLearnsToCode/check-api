module CheckdeskNotifications
  module Webhook
    def self.included(base)
      base.send :extend, ClassMethods
    end

    class Request < ::Net::HTTP
    end
  
    module ClassMethods
      def webhook_subscriptions
        @webhook_subscriptions
      end
  
      def webhook_subscriptions=(subscriptions)
        @webhook_subscriptions = subscriptions
      end

      def http_request(webhook, data)
        url = URI.parse(webhook)
        http = CheckdeskNotifications::Webhook::Request.new(url.host, url.port)
        http.use_ssl = webhook =~ /^https:/
        request = Net::HTTP::Post.new(url.request_uri)
        request.set_form_data(data)
        http.request(request)
      end
  
      def notifies_webhooks(subscriptions)
        send(:after_create, :notify_webhook_create)
        send(:after_update, :notify_webhook_update)
        send(:after_destroy, :notify_webhook_destroy)

        self.webhook_subscriptions = subscriptions
  
        send :include, InstanceMethods
      end
    end
  
    module InstanceMethods
      def sent_to_webhook
        @sent_to_webhook
      end
  
      def sent_to_webhook=(bool)
        @sent_to_webhook = bool
      end
  
      def notify_webhook_create
        self.notify_webhook(:create)
      end

      def notify_webhook_update
        self.notify_webhook(:update)
      end

      def notify_webhook_destroy
        self.notify_webhook(:destroy)
      end

      def parse_subscriptions(action)
        subscriptions = self.class.webhook_subscriptions.call(self)
        event = self.class.name.underscore + '.' + action.to_s
        subscriptions.select{ |s| s[:events].include?(event) }
      end
  
      def notify_webhook(action)
        subscriptions = self.parse_subscriptions(action)
        subscriptions.each do |subscription|
          method = "parse_parameters_for_#{subscription[:target]}_webhook"
          if self.respond_to?(method)
            webhook, data = self.send(method, action, subscription[:settings])
            callback = "parse_response_from_#{subscription[:target]}_webhook"
            unless webhook.blank?
              Rails.env == 'test' ? self.request_webhook(webhook, data, callback) : CheckdeskNotifications::Webhook::Worker.perform_async(webhook, data, callback, self.class.name, self.id)
            end
          end
        end
      end
  
      def request_webhook(webhook, data, callback)
        response = self.class.http_request(webhook, data)
        puts "Response from #{webhook} with #{data}: '#{response.body}' (HTTP #{response.code}). Response headers: #{response.to_hash}"
        self.sent_to_webhook = true
        self.send(callback, response) if self.respond_to?(callback)
      end
    end
  
    class Worker
      include ::Sidekiq::Worker
      include CheckdeskNotifications::Webhook::ClassMethods
  
      def perform(webhook, data, callback = nil, klass = nil, id = nil)
        response = http_request(webhook, data)
        if callback.present? && klass.present? && id.present?
          klass.constantize.find(id).send(callback, response)
        end
      end
    end
  end
end
