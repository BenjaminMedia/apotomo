module Apotomo
  # Almost like ActiveSupport::Callbacks but 76,6% less complex.
  #
  # Example:
  #
  #   class CatWidget < Apotomo::Widget
  #     define_hook :after_dinner
  #
  # Now you can add callbacks to your hook declaratively in your class.
  #
  #     after_dinner do puts "Ice cream!" end
  #     after_dinner :have_a_desert   # => refers to CatWidget#have_a_desert
  # 
  # Running the callbacks happens on instances. It will run the block and #have_a_desert from above.
  #
  #   cat.run_hook :after_dinner
  module Hooks
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def define_hook(name)
        accessor_name = "_#{name}_callbacks"
        
        setup_hook_accessors(accessor_name)
        define_hook_writer(name, accessor_name)
      end
      
      private
        def define_hook_writer(hook, accessor_name)
          instance_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
            def #{hook}(method=nil, &block)
              callback = block_given? ? block : method
              #{accessor_name} << callback
            end
          RUBY_EVAL
        end
        
        def setup_hook_accessors(accessor_name)
          class_inheritable_array(accessor_name, :instance_writer => false)
          send("#{accessor_name}=", [])  # initialize ivar.
        end
        
    end
    
    # Runs the callbacks (method/block) for the specified hook +name+. Additional arguments will 
    # be passed to the callback.
    #
    # Example:
    #
    #   cat.run_hook :after_dinner, "i want ice cream!"
    #
    # will invoke the callbacks like
    # 
    #   desert("i want ice cream!")
    #   block.call("i want ice cream!")
    def run_hook(name, *args)
      self.class.send("_#{name}_callbacks").each do |callback|
        send(callback, *args) and next if callback.kind_of? Symbol
        callback.call(*args) 
      end
    end
  end
end
