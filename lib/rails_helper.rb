class Helper < (defined?(ActionView::Base) ? ActionView::Base : Object)
  def Helper.version
    '1.2.0'
  end

  def Helper.dependencies
    {
      'rails_current'             => [ 'rails_current',             ' >= 1.0' ],
      'rails_default_url_options' => [ 'rails_default_url_options', ' >= 1.0' ]
    }
  end


  attr_accessor 'options'
  attr_accessor 'args'
  attr_accessor 'block'
  attr_accessor 'controller'
  attr_accessor 'modules'

  def initialize(*args, &block)
    @options = args.extract_options!.to_options!
    @args = args
    @block = block

    controllers, args = args.partition{|arg| ActionController::Base === arg}

    @controller = controllers.first || Helper.current_controller || Helper.mock_controller

    @modules = args

    @controller = controller
    @modules.push(nil) if @modules.empty?
    @modules.flatten.uniq.each do |mod|
      case mod
        when NilClass, :all, 'all'
          extend ::ActionView::Helpers
        when Module
          extend mod
        else
          raise ArgumentError, mod.class.name
      end
    end
  end

  ### see ./actionpack/test/controller/caching_test.rb OUCH!
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
          Helper.send(:include, Rails.application.routes.url_helpers)
        end
      end
    end
  end
end

Rails_helper = Helper
