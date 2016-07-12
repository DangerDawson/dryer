module Dryer
  module Cast
    module DeepFreeze
      class Error < StandardError
      end

      refine Object do
        def deep_frozen?
          deep_unfreezable.empty?
        end

        def deep_unfreezable
          objects = [self]
          check = []
          while object = objects.pop
            check << object
            next unless object.respond_to?(:instance_variable_names)
            object.instance_variable_names.each do |name|
              objects << object.instance_variable_get(name)
            end
          end
          check.uniq.reject(&:frozen?)
        end
      end
    end
  end
end
