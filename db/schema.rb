# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150303142455) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "conditions", force: :cascade do |t|
    t.string  "icd_9"
    t.boolean "indexed", default: false
    t.string  "doc_id"
    t.string  "mesh"
  end

  create_table "discharges", force: :cascade do |t|
    t.integer "sex"
    t.integer "age_unit"
    t.integer "age"
    t.integer "condition_id"
    t.integer "weight"
    t.integer "year"
    t.integer "icd9_chapter_id"
  end

  create_table "icd9_chapters", force: :cascade do |t|
    t.string "code"
    t.string "mesh"
    t.string "icd10"
    t.text   "wiki"
    t.string "title"
  end

  create_table "terms", force: :cascade do |t|
    t.integer "condition_id"
    t.string  "name"
  end

end
