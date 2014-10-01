require 'chef/knife'
require 'chef/knife/core/node_presenter'

module KnifeWip

  class NodeWip < Chef::Knife

    deps do
      require 'chef/node'
    end

    banner "knife node wip NODE DESCRIPTION"

    def run
      name = @name_args[0]
      description = @name_args[1..-1]

      if name.nil? || description.nil? || description.empty?
        show_usage
        ui.fatal("You must specify a node name and a description of what you are working on.")
        exit 1
      end

      wip_tag = "wip:#{ENV["USER"]}:#{description.join(" ")}"

      node = Chef::Node.load name
        (node.tags << wip_tag).uniq!
      node.save
      ui.info("Created WIP #{wip_tag} for node #{name}.")
    end

  end

  class NodeUnwip < Chef::Knife

    def run
      puts "lol unWIP"
    end

  end

  class WipList < Chef::Knife

    deps do
      require 'chef/node'
      require 'chef/environment'
      require 'chef/api_client'
      require 'chef/search/query'
    end

    include Chef::Knife::Core::NodeFormattingOptions

    banner "knife wip list"

    def run
      q = Chef::Search::Query.new

      query = URI.escape("tags:wip*", Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))

      result_items = []
      result_count = 0

      begin
        q.search('node', query) do |item|
          formatted_item = format_for_display(item)
          result_items << formatted_item
          result_count += 1
        end
      rescue Net::HTTPServerException => e
        msg = Chef::JSONCompat.from_json(e.response.body)["error"].first
        ui.error("knife wip list failed: #{msg}")
        exit 1
      end

      if ui.interchange?
        output({:results => result_count, :rows => result_items})
      else
        ui.msg "#{result_count} nodes found with work in progress"
        ui.msg("\n")
        result_items.each do |item|
          normalized_tags = []
          item.tags.each do |tag|
            next unless tag.start_with? "wip:"
            tag = tag.split(":")
            normalized_tags << tag[1, tag.length].join(":")
          end
          output("#{item.name}: #{normalized_tags.join(", ")}")
        end
      end
    end

  end

end
