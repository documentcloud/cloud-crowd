window.Console = {
  
  POLL_INTERVAL : 3000,
  
  initialize : function() {
    this._queue = $('#jobs');
    this.getJobs();
  },
  
  getJobs : function() {
    $.get('/jobs', null, function(resp) {
      Console._jobs = resp;
      Console.renderJobs();
      setTimeout(Console.getJobs, Console.POLL_INTERVAL);
    }, 'json');
  },
  
  renderJob : function(job) {
    this._queue.prepend('<div class="job" id="job_' + job.id + '" style="width:' + job.width + '%; background: #' + job.color + ';"><div class="completion" style="width:' + job.percent_complete + '%;"></div><div class="percent_complete">' + job.percent_complete + '%</div><div class="job_id">#' + job.id + '</div></div>');
  },
  
  updateJob : function(job, jobEl) {
    jobEl.animate({width : job.width + '%'});
    $('.completion', jobEl).animate({width : job.percent_complete + '%'});
    $('.percent_complete', jobEl).html(job.percent_complete + '%');
  },
  
  renderJobs : function() {
    var totalUnits = 0;
    var totalWidth = this._queue.width();
    var jobIds = [];
    $.each(this._jobs, function() { 
      jobIds.push(this.id);
      totalUnits += this.work_units; 
    });
    $.each(this._jobs, function() {
      this.width  = (this.work_units / totalUnits) * 100;
      var jobEl = $('#job_' + this.id);
      jobEl[0] ? Console.updateJob(this, jobEl) : Console.renderJob(this);
    });
    $.each($('.job'), function() {
      if (jobIds.indexOf(parseInt(this.id.replace(/\D/g, ''), 10)) < 0) $(this).remove();
    });
  }
  
};

$(document).ready(function() { Console.initialize(); });