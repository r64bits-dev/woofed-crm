class AccountRecord < ApplicationRecord
  include Applicable
  self.abstract_class = true
end
