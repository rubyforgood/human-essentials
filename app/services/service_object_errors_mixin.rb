module ServiceObjectErrorsMixin
  #
  # This module is can be included into service object like
  # classes so that they get the similiar interface commonly used
  # by active records. Here is an example of a how you could interact
  # with a service object with this included.
  #
  # service = ExampleService.new(wibble: 'wobble')
  # service.perform
  #
  # if service.errors.present?
  #   # All good! You can proceed to use some public methods
  #   # in the case that you stored the output of `call` in a
  #   # instance variable.
  #   service.some_public_method
  # else
  #   # Output the errors like
  #   puts(service.errors)
  #   # Or like this to get an array of errors
  #   puts(service.errors.full_messages)
  # end
  #
  # The aim is to keep the interfaces common! You can see this
  # in use in the `KitCreateService`

  def self.included(base)
    base.extend(ClassMethods, ActiveModel::Naming)
  end

  def errors
    @errors ||= ActiveModel::Errors.new(self)
  end

  def read_attribute_for_validation(attr)
    send(attr)
  end

  module ClassMethods
    def human_attribute_name(attr, _options = {})
      attr
    end

    def lookup_ancestors
      [self]
    end
  end
end

