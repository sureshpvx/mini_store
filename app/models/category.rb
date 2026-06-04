class Category < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [:name]

  has_many :subcategories,
           class_name: "Category",
           foreign_key: "parent_id",
           dependent: :destroy,
           inverse_of: :parent

  belongs_to :parent,
             class_name: "Category",
             optional: true,
             inverse_of: :subcategories

  has_many :products, dependent: :nullify

  validates :name, presence: true, length: { maximum: 100 }

  def full_name
    parent ? "#{parent.name} → #{name}" : name
  end
end