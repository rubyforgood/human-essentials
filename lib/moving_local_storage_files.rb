# Description TBA
class ActiveStorageBlob < ApplicationRecord
end

# Description TBA
class ActiveStorageAttachment < ApplicationRecord
  belongs_to :blob, class_name: "ActiveStorageBlob"
  belongs_to :record, polymorphic: true
end

ActiveStorageAttachment.find_each do |attachment|
  name = attachment.name

  source = attachment.record.send(name).path

  dest_dir = Rails.root.join(
    "storage",
    attachment.blob.key.first(2),
    attachment.blob.key.first(4).last(2)
  ).to_s
  dest = File.join(dest_dir, attachment.blob.key)

  FileUtils.mkdir_p(File.dirname(dest))

  FileUtils.cp(source, dest)
end
