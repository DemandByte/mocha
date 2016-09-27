require 'mocha/ruby_version'
require 'mocha/class_method'

module Mocha

  class AnyInstanceMethod < ClassMethod

    def mock
      stubbee.any_instance.mocha
    end

    def reset_mocha
      stubbee.any_instance.reset_mocha
    end

    def restore_original_method
      unless RUBY_V2_PLUS
        if @original_method && @original_method.owner == default_definition_target
          default_definition_target.send(:define_method, method_name, @original_method)
          Module.instance_method(@original_visibility).bind(default_definition_target).call(method_name)
        end
      end
    end

    def method_visibility(method_name)
      (default_definition_target.public_instance_methods(true).include?(method_name) && :public) ||
        (default_definition_target.protected_instance_methods(true).include?(method_name) && :protected) ||
        (default_definition_target.private_instance_methods(true).include?(method_name) && :private)
    end

    private

    def original_method(method_name)
      default_definition_target.instance_method(method_name)
    end

    def original_method_defined_on_stubbee?
      @original_method && @original_method.owner == default_definition_target
    end

    def remove_original_method_from_stubbee
      default_definition_target.send(:remove_method, method_name)
    end

    def prepend_module
      @definition_target = PrependedModule.new
      default_definition_target.__send__ :prepend, @definition_target
    end

    def stub_method_definition
      filename, line_number_of_method_implementation = __FILE__, __LINE__ + 2
      method_implementation = <<-CODE
      def #{method_name}(*args, &block)
        self.class.any_instance.mocha.method_missing(:#{method_name}, *args, &block)
      end
      CODE
      [method_implementation, filename, line_number_of_method_implementation]
    end

    def default_definition_target
      stubbee
    end

  end

end
