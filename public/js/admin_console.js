window.Console = {
  
  initialize : function() {
    this._queue = $('#jobs');
    this.getJobs();
  },
  
  getJobs : function() {
    $.get('/jobs', null, function(resp) {
      Console._jobs = resp;
      Console.renderJobs();
    }, 'json');
  },
  
  renderJobs : function() {
    var queue = this._queue;
    var totalUnits = 0;
    var totalWidth = queue.width();
    $.each(this._jobs, function() { 
      totalUnits += this.work_units; 
    });
    $.each(this._jobs, function() {
      this.width  = (this.work_units / totalUnits) * 100;
    });
    queue.html('');
    $.each(this._jobs.reverse(), function() {
      queue.append('<div class="job" style="width:' + this.width + '%; background: #' + this.color + ';"><div class="job_id">#' + this.id + '</div></div>');
    });
  }
  
};

$(document).ready(function() { Console.initialize(); });