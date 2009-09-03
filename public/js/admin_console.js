// The Console handles all of the Admin interaction with the active workers
// and job queue.
//
// Think about pulling in the DCJS framework, instead of just raw jQuery here.
// Leaving it hacked together like this just cries out for templates, dunnit?
window.Console = {
  
  // Maximum number of data points to record and graph.
  MAX_DATA_POINTS : 100,
  
  // Milliseconds between polling the central server for updates to Job progress.
  POLL_INTERVAL : 3000,
  
  // Default speed for all animations.
  ANIMATION_SPEED : 300,
  
  GRAPH_OPTIONS : {
    xaxis :   {mode : 'time', timeformat : '%M:%S'},
    legend :  {backgroundColor : '#bbb', backgroundOpacity : 0.85, margin : 6},
    grid :    {backgroundColor : '#7f7f7f', color : '#555', tickColor : '#666', borderWidth : 2}
  },
  
  // Starting the console begins polling the server.
  initialize : function() {
    this._dataPoints = [];
    this._queue = $('#jobs');
    $(window).bind('resize', Console.renderGraphs);
    this.getStatus();
  },
  
  // Request the lastest status of all jobs and workers, re-render or update
  // the DOM to reflect.
  getStatus : function() {
    $.get('/status', null, function(resp) {
      Console._jobs       = resp.incomplete_jobs;
      Console._completed  = resp.complete_jobs;
      Console._workers    = resp.workers;
      Console.recordDataPoint();
      $('#queue').toggleClass('no_jobs', Console._jobs.length <= 0);
      Console.renderJobs();
      Console.renderWorkers();
      Console.renderGraphs();
      setTimeout(Console.getStatus, Console.POLL_INTERVAL);
    }, 'json');
  },
  
  // Render an individual job afresh.
  renderJob : function(job) {
    this._queue.append('<div class="job" id="job_' + job.id + '" style="width:' + job.width + '%; background: #' + job.color + ';"><div class="completion done_' + job.percent_complete + '" style="width:' + job.percent_complete + '%;"></div><div class="percent_complete">' + job.percent_complete + '%</div><div class="job_id">#' + job.id + '</div></div>');
  },
  
  // Animate the update to an existing job in the queue.
  updateJob : function(job, jobEl) {
    jobEl.animate({width : job.width + '%'}, this.ANIMATION_SPEED);
    var completion = $('.completion', jobEl);
    completion.animate({width : job.percent_complete + '%'}, this.ANIMATION_SPEED);
    completion[0].className = completion[0].className.replace(/\b\done_d+\b/, 'done_' + job.percent_complete);
    $('.percent_complete', jobEl).html(job.percent_complete + '%');
  },
  
  // Render all jobs, calculating relative widths and completions.
  renderJobs : function() {
    var totalUnits = 0;
    var totalWidth = this._queue.width();
    var jobIds = [];
    $.each(this._jobs, function() { 
      jobIds.push(this.id);
      totalUnits += this.work_units; 
    });
    $.each($('.job'), function() {
      var el = this;
      if (jobIds.indexOf(parseInt(el.id.replace(/\D/g, ''), 10)) < 0) {
        $(el).animate({width : '0%'}, Console.ANIMATION_SPEED - 50, 'linear', function() {
          $(el).remove();
        });
      }
    });
    $.each(this._jobs, function() {
      this.width  = (this.work_units / totalUnits) * 100;
      var jobEl = $('#job_' + this.id);
      jobEl[0] ? Console.updateJob(this, jobEl) : Console.renderJob(this);
    });
  },
  
  // Re-render all workers from scratch each time.
  renderWorkers : function() {
    var header = $('#sidebar_header');
    $('.has_workers', header).html(this._workers.length + " Active Worker Daemons");
    header.toggleClass('no_workers', this._workers.length <= 0);
    $('#workers').html($.map(this._workers, function(w) { 
      return '<div class="worker ' + w.status + '" title="status: ' + w.status + '">' + w.name + '</div>';
    }).join(''));
  },
  
  // Record the current state and re-render all graphs.
  recordDataPoint : function() {
    var dataPoint = {
      timestamp  : (new Date()).getTime(),
      incomplete : Console._jobs.length,
      complete   : Console._completed.length,
      workers    : Console._workers.length
    };
    Console._dataPoints.push(dataPoint);
    if (Console._dataPoints.length > Console.MAX_DATA_POINTS) Console._dataPoints.shift();
  },
  
  // Convert our recorded data points into a format Flot can understand.
  renderGraphs : function() {
    var complete = [], incomplete = [], workers = [];
    for (var i=0; i<Console._dataPoints.length; i++) {
      var point = Console._dataPoints[i];
      incomplete.push([point.timestamp, point.incomplete]);
      complete.push([point.timestamp, point.complete]);
      workers.push([point.timestamp, point.workers]);
    }
    var series = [
      {label : 'Jobs in Queue', color : '#e93', data : incomplete},
      // {label : 'Completed Jobs', data : complete},
      {label : 'Active Workers', color : '#559', data : workers}
    ];
    $.plot($('#main_graph'), series, Console.GRAPH_OPTIONS);
  }
  
};

$(document).ready(function() { Console.initialize(); });