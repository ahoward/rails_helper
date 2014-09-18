class Helper < (defined?(ActionView::Base) ? ActionView::Base : Object)
  def Helper.version
    '2.2.2'
  end

  def Helper.dependencies
    {
      'rails_current'             => [ 'rails_current',             ' >= 1.0' ],
      'rails_default_url_options' => [ 'rails_default_url_options', ' >= 1.0' ]
    }
  end

  def Helper.new(*args, &block)
    options = args.extract_options!.to_options!
    controllers, args = args.partition{|arg| ActionController::Base === arg}
    controller = controllers.first || Helper.current_controller || Helper.mock_controller

    controller_class = controller.send(:class)

    helpers = args
    helpers.push(nil) if helpers.empty?

    helpers.flatten!
    helpers.uniq!

    modules = []

    helpers.each do |mod|
      case mod
        when NilClass, :all, 'all'
          controller_class.send(:all_application_helpers).each do |name|
            file_name  = name.to_s.underscore + '_helper'
            mod = file_name.camelize.constantize
            modules.push(mod)
          end
        when Module
          modules.push(mod)
        else
          raise(ArgumentError, mod.inspect)
      end
    end

    view_class =
      Class.new(self) do
        modules.each do |mod|
          include mod
        end
        self.helpers = helpers
      end

    view_class.allocate.tap do |helper|
      helper.send(:initialize, context=nil, assigns={}, controller, formats=nil)
      helper
    end
  end

  attr_accessor 'controller'

  if Helper.superclass == ::Object
    def initialize(*args, &block)
      :noop
    end

    def Helper.helpers=(*args)
      :noop
    end
  end

# see ./actionpack/test/controller/caching_test.rb OUCH!
#
  def Helper.mock_controller
    require 'rails'
    require 'action_controller'
    require 'action_dispatch/testing/test_request.rb'
    require 'action_dispatch/testing/test_response.rb'

    store = ActiveSupport::Cache::MemoryStore.new

    controller = mock_controller_class.new
    controller.perform_caching = true
    controller.cache_store = store

    request = ActionDispatch::TestRequest.new
    response = ActionDispatch::TestResponse.new

    controller.request = request
    controller.response = response

    singleton_class =
      class << controller
        self
      end

    singleton_class.module_eval do
      define_method(:default_url_options) do
        @default_url_options ||= (
          defined?(DefaultUrlOptions) ? DefaultUrlOptions.dup : {}
        )
      end
    end

    controller
  end

  def Helper.mock_controller_class
    unless const_defined?(:Controller)
      controller_class =
        if defined?(::ApplicationController)
          Class.new(::ApplicationController)
        else
          Class.new(::ActionController::Base)
        end
      const_set(:Controller, controller_class)
    end
    return const_get(:Controller)
  end

  def Helper.current_controller
    Current.controller
  end

  def _routes
    Rails.application.routes
  end

  def default_url_options
    defined?(DefaultUrlOptions) ? DefaultUrlOptions : {}
  end

  def session
    controller.session
  end

  if defined?(::Rails)
    if defined?(Rails::Engine)
      class Engine < Rails::Engine
        config.after_initialize do
          Rails.application.routes.install_helpers(Helper)
        end
      end
    end
  end
end

Rails_helper = Helper
