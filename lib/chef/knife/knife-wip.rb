require 'chef/knife'
require 'chef/knife/core/node_presenter'
require 'app_conf'

module KnifeWip

  # Public: collection namespace for some helper functions and methods
  module Helpers

    # Public: load all plugins that are configured
    #
    # this method merely tries to require the plugin files, instantiates an
    # object from them and then stores it in @plugins. That way the knife
    # commands can just call all plugins however they want from there.
    #
    # Returns nothing
    def load_plugins

      @plugins ||= []


      app_config[:plugins].each do |plugin|
        begin
          require "knife-wip/plugins/#{plugin["name"].downcase}"
          # apparently this is the way to dynamically instantiate ruby objects
          @plugins << KnifeWip::Plugins.const_get(plugin["name"].capitalize).new(plugin)
        rescue LoadError
          ui.warn "Configured plugin '#{plugin["name"]}' doesn't exist."
        end

      end

    end

    # Public: get the configuration loaded from the yaml files
    #
    # Returns the appconf object with config loaded
    def app_config
      return @app_config unless @app_config.nil?

      @app_config = ::AppConf.new
      load_paths = []
      # first look for configuration in the cookbooks folder
      #load_paths << File.expand_path("#{cookbook_path.gsub('cookbooks','')}/config/knife-wip-config.yml")
      # or see if we are in the cookbooks repo
      load_paths << File.expand_path('config/knife-wip-config.yml')
      # global config in /etc has higher priority
      load_paths << '/etc/knife-wip-config.yml'
      # finally the user supplied config file is loaded
      load_paths << File.expand_path('~/.chef/knife-wip-config.yml')

      # load all the paths
      load_paths.each do |load_path|
        if File.exists?(load_path)
          ui.info "loading #{load_path}"
          @app_config.load(load_path)
        end
      end

      @app_config
    end

  end

  # Public: class to inherit from for plugins. Basically a cheap hack to get
  # some control over whether or not a plugin implements the correct methods
  class Plugin
    include ::KnifeWip::Helpers

    def initialize(config)
      @config = config
    end

    def wip_start(user, tag, node)
      ui.warn "Warning: #{self.class} doesn't implement the 'wip_start' method."
      ui.warn "No announcements performed for #{self.class}"
    end

    def wip_stop(user, tag, node)
      ui.warn "Warning: #{self.class} doesn't implement the 'wip_stop' method."
      ui.warn "No announcements performed for #{self.class}"
    end

  end


  class NodeWip < Chef::Knife
    include KnifeWip::Helpers

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

      load_plugins

      wip_tag = "wip:#{ENV["USER"]}:#{description.join(" ")}"

      node = Chef::Node.load name
        (node.tags << wip_tag).uniq!
      node.save
      ui.info("Created WIP \"#{wip_tag}\" for node #{name}.")
      @plugins.each do |plugin|
        plugin.wip_start(ENV["USER"], wip_tag, name)
      end
    end

  end

  class NodeUnwip < Chef::Knife

    deps do
      require 'chef/node'
    end

    banner "knife node unwip NODE DESCRIPTION"

    def run
      name = @name_args[0]
      description = @name_args[1..-1].join(" ")

      if name.nil? || description.nil? || description.empty?
        show_usage
        ui.fatal("You must specify a node name and a WIP description.")
        exit 1
      end

      node = Chef::Node.load name
      tag = "wip:#{ENV["USER"]}:#{description}"
      success = node.tags.delete(tag).nil? ? false : true

      node.save
      if success == false
        message = "Nothing has changed. The WIP description requested to be deleted does not exist."
      else
        message = "Deleted WIP description \"#{tag}\" for node #{name}."
      end
      ui.info(message)
      @plugins.each do |plugin|
        plugin.wip_stop(ENV["USER"], wip_tag, name)
      end
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
