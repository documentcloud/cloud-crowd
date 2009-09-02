// Think about pulling in the DCJS framework, instead of just raw jQuery here.
window.Console = {
  
  POLL_INTERVAL : 3000,
  
  ANIMATION_SPEED : 300,
  
  initialize : function() {
    this._queue = $('#jobs');
    this.getStatus();
  },
  
  getStatus : function() {
    $.get('/status', null, function(resp) {
      Console._jobs     = resp.jobs;
      Console._workers  = resp.workers;
      $('#queue').toggleClass('no_jobs', Console._jobs.length <= 0);
      Console.renderJobs();
      Console.renderWorkers();
      setTimeout(Console.getStatus, Console.POLL_INTERVAL);
    }, 'json');
  },
  
  renderJob : function(job) {
    this._queue.prepend('<div class="job" id="job_' + job.id + '" style="width:' + job.width + '%; background: #' + job.color + ';"><div class="completion" style="width:' + job.percent_complete + '%;"></div><div class="percent_complete">' + job.percent_complete + '%</div><div class="job_id">#' + job.id + '</div></div>');
  },
  
  updateJob : function(job, jobEl) {
    jobEl.animate({width : job.width + '%'}, this.ANIMATION_SPEED);
    $('.completion', jobEl).animate({width : job.percent_complete + '%'}, this.ANIMATION_SPEED);
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
    $.each($('.job'), function() {
      if (jobIds.indexOf(parseInt(this.id.replace(/\D/g, ''), 10)) < 0) $(this).remove();
    });
    $.each(this._jobs.reverse(), function() {
      this.width  = (this.work_units / totalUnits) * 100;
      var jobEl = $('#job_' + this.id);
      jobEl[0] ? Console.updateJob(this, jobEl) : Console.renderJob(this);
    });
  },
  
  renderWorkers : function() {
    $('#workers').html($.map(this._workers, function(w) { 
      return '<div class="worker ' + w.thread_status + '">' + w.name + '</div>';
    }).join(''));
  }
  
};

$(document).ready(function() { Console.initialize(); });