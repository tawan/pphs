require_relative './discharge'
require_relative './condition'

#Discharge.delete_all
#Condition.delete_all

$stdin.each_line do |line|
  icd = line[27..31]
  icd.gsub!(/-/,'')
  d = Discharge.new :sex => line[6].to_i,
    :age_unit => line[3].to_i,
    :age => line[4..5].to_i,
    :year => line[0..1].to_i,
    :weight => line[20..24].to_i,
    :condition => Condition.find_or_create_by(:icd_9 => icd)
  d.save!
end
