class Category < ApplicationRecord
  # children (subcategories)
  has_many :subcategories,
           class_name: "Category",
           foreign_key: "parent_id",
           dependent: :destroy,
           inverse_of: :parent

  # parent category
  belongs_to :parent,
             class_name: "Category",
             optional: true,
             inverse_of: :subcategories

  # products under this category
  has_many :products, dependent: :nullify

  def full_name
    parent ? "#{parent.name} → #{name}" : name
  end
end