# Complete schema for CloudCrowd.
ActiveRecord::Schema.define(:version => CloudCrowd::SCHEMA_VERSION) do

  create_table "jobs", :force => true do |t|
    t.integer  "status",                      :null => false
    t.text     "inputs",                      :null => false
    t.string   "action",                      :null => false
    t.text     "options",                     :null => false
    t.text     "outputs"
    t.float    "time"
    t.string   "callback_url"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "node_records", :force => true do |t|
    t.string   "host",                                :null => false
    t.string   "ip_address",                          :null => false
    t.integer  "port",                                :null => false
    t.text     "enabled_actions", :default => '',     :null => false
    t.boolean  "busy",            :default => false,  :null => false
    t.string   "tag"
    t.integer  "max_workers"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "work_units", :force => true do |t|
    t.integer  "status",                          :null => false
    t.integer  "job_id",                          :null => false
    t.text     "input",                           :null => false
    t.string   "action",                          :null => false
    t.integer  "attempts",      :default => 0,    :null => false
    t.integer  "node_record_id"
    t.integer  "worker_pid"
    t.integer  "reservation"
    t.float    "time"
    t.text     "output"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "jobs", ["status"], :name => "index_jobs_on_status"
  add_index "work_units", ["job_id"], :name => "index_work_units_on_job_id"
  add_index "work_units", ["worker_pid"], :name => "index_work_units_on_worker_pid"
  add_index "work_units", ["worker_pid", "status"], :name => "index_work_units_on_worker_pid_and_status"
  add_index "work_units", ["worker_pid", "node_record_id"], :name => "index_work_units_on_worker_pid_and_node_record_id"
end
