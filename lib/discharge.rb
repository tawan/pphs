require_relative 'db_conn'
class Discharge < ActiveRecord::Base
  belongs_to :condition
  belongs_to :icd9_chapter

  def self.from_07
    where(:year => 7)
  end

  def self.from_10
    where(:year => 10)
  end

  def self.male
    where(:sex => 1)
  end

  def self.female
    where(:sex => 2)
  end

  def self.in_years
    where(:age_unit => 1)
  end

  def self.age_between(more, less)
    if more == 0
      return where("age <= ? OR age_unit > 1", less)
    end
    in_years.where("age >= ? AND age <= ?", more, less)
  end

  def age_norm
    return 0 if age_unit > 1
    age
  end
end
