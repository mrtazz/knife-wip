module KnifeWip
  module Plugins
    class Irccat < KnifeWip::Plugin

      TEMPLATES = {
        :start => '#BOLD#PURPLECHEF:#NORMAL %{user} started work #TEAL%{tag}#NORMAL on #RED%{node}#NORMAL',
        :stop  => '#BOLD#PURPLECHEF:#NORMAL %{user} stopped work #TEAL%{tag}#NORMAL on #RED%{node}#NORMAL'
      }

      def wip_start(user, tag, node)
        send_to_irccat(TEMPLATES[:start] % {
            :user => user,
            :tag  => tag,
            :node => node,
        })
      end

      def wip_stop(user, tag, node)
        send_to_irccat(TEMPLATES[:stop] % {
            :user => user,
            :tag  => tag,
            :node => node,
        })
      end

      private
      def send_to_irccat(message)
        @config["channels"].each do |channel|
          begin
            # Write the message using a TCP Socket
            socket = TCPSocket.open(@config["server"], @config["port"])
            socket.write("#{channel} #{message}")
          rescue Exception => e
            ui.error 'Failed to post message with irccat.'
            ui.error e.to_s
          ensure
            socket.close unless socket.nil?
          end
        end
      end

    end
  end
end
