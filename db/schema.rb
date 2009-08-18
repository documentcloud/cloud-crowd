# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090817192006) do

  create_table "jobs", :force => true do |t|
    t.integer  "status",       :null => false
    t.text     "inputs",       :null => false
    t.string   "action",       :null => false
    t.text     "options",      :null => false
    t.string   "callback_url"
    t.string   "owner_email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "work_units", :force => true do |t|
    t.integer  "status",     :null => false
    t.integer  "job_id",     :null => false
    t.string   "input",      :null => false
    t.float    "time"
    t.text     "output"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "work_units", ["job_id"], :name => "index_work_units_on_job_id"
  add_index "work_units", ["status"], :name => "index_work_units_on_status"

end
