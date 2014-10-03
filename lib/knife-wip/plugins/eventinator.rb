require 'chef/knife'

module KnifeWip
  module Plugins
    class Eventinator < KnifeWip::Plugin

      def wip_start(user, tag, node)
        event_data = {
            :tag => 'knife',
            :username => user,
            :status => "#{user} started work '#{tag}' on #{node}",
            :metadata => {
                :node_name => node,
                :tag => tag
            }.to_json
        }
        eventinate(event_data)
      end

      def wip_stop(user, tag, node)
        event_data = {
            :tag => 'knife',
            :username => user,
            :status => "#{user} stopped work '#{tag}' on #{node}",
            :metadata => {
                :node_name => node,
                :tag => tag
            }.to_json
        }
        eventinate(event_data)
      end

      private
      def eventinate(event_data)
          begin
            uri = URI.parse(@config["url"])
          rescue Exception => e
            ui.error 'Could not parse URI for Eventinator.'
            ui.error e.to_s
            return
          end

          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = @config["read_timeout"] || 5

          request = Net::HTTP::Post.new(uri.request_uri)
          request.set_form_data(event_data)

          begin
            response = http.request(request)
            ui.error "Eventinator at #{@config["url"]} did not receive a good response from the server" if response.code != '200'
          rescue Timeout::Error
            ui.error "Eventinator timed out connecting to #{@config["url"]}. Is that URL accessible?"
          rescue Exception => e
            ui.error 'Eventinator error.'
            ui.error e.to_s
          end
      end

    end
  end
end
