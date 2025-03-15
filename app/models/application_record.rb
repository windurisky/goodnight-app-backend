class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  connects_to database: {
    writing: :primary,
    reading: :primary_replica
  }

  private

  def generate_uuid_v7
    return if self.class.attribute_types["id"].type != :string

    self.id ||= SecureRandom.uuid_v7
  end
end
