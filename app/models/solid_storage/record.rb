
module SolidStorage
  class Record < ActiveRecord::Base
    self.abstract_class = true

    connects_to(**SolidStorage.connects_to) if SolidStorage.connects_to.present?
  end
end
