# TODO: Move this out of models
# Validates that an organization logo is the correct size
class DimensionsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if record.send("#{attribute}?".to_sym)
      dimensions = Paperclip::Geometry.from_file(value.queued_for_write[:original].path)
      width = options[:width]
      height = options[:height]

      record.errors[attribute] << "Width must be less than #{width}px" unless dimensions.width <= width
      record.errors[attribute] << "Height must be less than #{height}px" unless dimensions.height <= height
    end
  end
end
