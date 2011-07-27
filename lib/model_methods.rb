module ModelMethods

  module Attachment

    def download_url
      "/projects/#{ self.container.project.id }/issues/#{ self.container.id }/attachments/#{self.id}/file?#{self.filename}"
    end
  end

  module Base
    def touch(attribute = nil)
      current_time = DateTime.now.utc

      if attribute
        write_attribute(attribute, current_time)
      else
        write_attribute('updated_at', current_time) if respond_to?(:updated_at)
        write_attribute('updated_on', current_time) if respond_to?(:updated_on)
      end
      save!
    end
  end
  
end

