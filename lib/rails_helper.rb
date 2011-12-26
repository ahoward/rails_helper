class Helper
  def Helper.version() '1.1.0' end

  def Helper.dependencies
    {
      'rails_current' => [ 'rails_current', ' >= 1.0' ]
    }
  end


  if defined?(Rails::Engine)

    class Engine < Rails::Engine
      config.after_initialize do
        if defined?(ActionView::Helpers)
          ::Helper.send(:include, ActionView::Helpers)
        end

        if defined?(Rails.application.routes.url_helpers)
          ::Helper.send(:include, Rails.application.routes.url_helpers)
        end
      end
    end

  end

  def controller
    @controller ||= (Helper.current_controller || Helper.mock_controller)
    @controller
  end

  def controller=(controller)
    @controller = controller
  ensure
    default_url_options[:protocol] = @controller.request.protocol
    default_url_options[:host] = @controller.request.host
    default_url_options[:port] = @controller.request.port
  end

  def set_controller(controller)
    self.controller = controller
  end

  controller_delegates = %w(
    render
    render_to_string
  )

  controller_delegates.each do |method|
    module_eval <<-__, __FILE__, __LINE__
      def #{ method }(*args, &block)
        controller.#{ method }(*args, &block)
      end
    __
  end

  class << Helper
    def mock_controller
      ensure_rails_application do
        require 'action_dispatch/testing/test_request.rb'
        require 'action_dispatch/testing/test_response.rb'
        store = ActiveSupport::Cache::MemoryStore.new
        controller = 
          begin
            ApplicationController.new
          rescue NameError
            ActionController::Base.new
          end
        controller.perform_caching = true
        controller.cache_store = store
        request = ActionDispatch::TestRequest.new
        response = ActionDispatch::TestResponse.new
        controller.request = request
        controller.response = response
        controller.send(:initialize_template_class, response)
        controller.send(:assign_shortcuts, request, response)
        controller.send(:default_url_options).merge!(DefaultUrlOptions) if defined?(DefaultUrlOptions)
        controller
      end
    end

    def ensure_rails_application(&block)
      if Rails.application.nil?
        mock = Class.new(Rails::Application)
        Rails.application = mock.instance
        begin
          block.call()
        ensure
          Rails.application = nil
        end
      else
        block.call()
      end
    end

    def current_controller
      Current.controller
    end
  end
end

Rails_helper = Helper
