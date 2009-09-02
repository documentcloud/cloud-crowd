# Complete schema for CloudCrowd.
ActiveRecord::Schema.define(:version => 1) do

  create_table "jobs", :force => true do |t|
    t.integer  "status",                      :null => false
    t.text     "inputs",                      :null => false
    t.string   "action",                      :null => false
    t.text     "options",                     :null => false
    t.text     "outputs"
    t.float    "time"
    t.string   "callback_url"
    t.string   "owner_email"
    t.integer  "lock_version", :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "work_units", :force => true do |t|
    t.integer  "status",                          :null => false
    t.integer  "job_id",                          :null => false
    t.text     "input",                           :null => false
    t.string   "action",                          :null => false
    t.integer  "attempts",     :default => 0,     :null => false
    t.integer  "lock_version", :default => 0,     :null => false
    t.string   "worker"
    t.float    "time"
    t.text     "output"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  create_table "worker_records", :force => true do |t|
    t.string   "name",          :null => false
    t.string   "thread_status", :null => false
    t.integer  "job_id"
    t.integer  "work_unit_id"
    t.string   "action"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "jobs", ["status"], :name => "index_jobs_on_status"
  add_index "work_units", ["job_id"], :name => "index_work_units_on_job_id"
  add_index "work_units", ["status", "worker", "action"], :name => "index_work_units_on_status_and_worker_and_action"
  add_index "worker_records", ["name"], :name => "index_worker_records_on_name"
  add_index "worker_records", ["updated_at"], :name => "index_worker_records_on_updated_at"

end
