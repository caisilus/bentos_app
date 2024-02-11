class Observation < ApplicationRecord
  has_and_belongs_to_many :species
  belongs_to :place, optional: true
  has_many_attached :photos

  def attach_base64_photo(encoded_photo, filename)
    decoded_image = Base64.decode64(encoded_photo)

    photos.attach(
      io: StringIO.new(decoded_image),
      content_type: 'image/jpeg',
      filename: filename
    )
  end
end
