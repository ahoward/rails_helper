class Helper < (defined?(ActionView::Base) ? ActionView::Base : Object)
  def Helper.version
    '2.0.0'
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

    helpers = args
    helpers.push(nil) if helpers.empty?

    helpers.flatten!
    helpers.uniq!

    helpers.map! do |mod|
      case mod
        when NilClass, :all, 'all'
          ::ActionView::Helpers
        when Module
          mod
        else
          raise ArgumentError, mod.class.name
      end
    end

    view_class =
      Class.new(self) do
        helpers.each do |helper|
          include helper
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
    require 'action_dispatch/testing/test_request.rb'
    require 'action_dispatch/testing/test_response.rb'

    store = ActiveSupport::Cache::MemoryStore.new

    controller = ApplicationController.new
    controller.perform_caching = true
    controller.cache_store = store

    request = ActionDispatch::TestRequest.new
    response = ActionDispatch::TestResponse.new

    controller.request = request
    controller.response = response

    controller.send(:default_url_options).merge!(DefaultUrlOptions) if defined?(DefaultUrlOptions)
    controller
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
