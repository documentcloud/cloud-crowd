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
  
  // Keep this in sync with the map in cloud-crowd.rb
  DISPLAY_STATUS_MAP : ['unknown', 'processing', 'succeeded', 'failed', 'splitting', 'merging'],    
  
  // Images to preload
  PRELOAD_IMAGES : ['images/server_error.png'],
  
  // All options for drawing the system graphs.
  GRAPH_OPTIONS : {
    xaxis   : {mode : 'time', timeformat : '%M:%S'},
    yaxis   : {tickDecimals : 0},
    legend  : {show : false},
    grid    : {backgroundColor : '#7f7f7f', color : '#555', tickColor : '#666', borderWidth : 2}
  },
  JOBS_COLOR        : '#db3a0f',
  NODES_COLOR       : '#1870ab',
  WORKERS_COLOR     : '#45a4e5',
  WORK_UNITS_COLOR  : '#ffba14',
  
  // Starting the console begins polling the server.
  initialize : function() {
    this._jobsHistory = [];
    this._nodesHistory = [];
    this._workersHistory = [];
    this._workUnitsHistory = [];
    this._histories = [this._jobsHistory, this._nodesHistory, this._workersHistory, this._workUnitsHistory];
    this._queue = $('#jobs');
    this._workerInfo = $('#worker_info');
    this._disconnected = $('#disconnected');
    $(window).bind('resize', Console.renderGraphs);
    $('#nodes .worker').live('click', Console.getWorkerInfo);
    $('#workers_legend').css({background : this.WORKERS_COLOR});
    $('#nodes_legend').css({background : this.NODES_COLOR});
    this.getStatus();
    $.each(this.PRELOAD_IMAGES, function(){ var i = new Image(); i.src = this; });
  },
  
  // Request the lastest status of all jobs and workers, re-render or update
  // the DOM to reflect.
  getStatus : function() {
    $.ajax({url : 'status', dataType : 'json', success : function(resp) {
      Console._jobs           = resp.jobs;
      Console._nodes          = resp.nodes;
      Console._workUnitCount  = resp.work_unit_count;
      Console._workerCount    = Console.countWorkers();
      Console.recordDataPoint();
      if (Console._disconnected.is(':visible')) Console._disconnected.fadeOut(Console.ANIMATION_SPEED);
      $('#queue').toggleClass('no_jobs', Console._jobs.length <= 0);
      Console.renderJobs();
      Console.renderNodes();
      Console.renderGraphs();
      setTimeout(Console.getStatus, Console.POLL_INTERVAL);
    }, error : function(request, status, errorThrown) {
      if (!Console._disconnected.is(':visible')) Console._disconnected.fadeIn(Console.ANIMATION_SPEED);
      setTimeout(Console.getStatus, Console.POLL_INTERVAL);
    }});
  },
  
  // Count the total number of workers in the current list of nodes.
  countWorkers : function() {
    var sum = 0;
    for (var i=0; i < this._nodes.length; i++) sum += this._nodes[i].workers.length;
    return sum;
  },
  
  // Render an individual job afresh.
  renderJob : function(job) {
    this._queue.append('<div class="job" id="job_' + job.id + '" style="width:' + job.width + '%; background: #' + job.color + ';"><div class="completion ' + (job.percent_complete <= 0 ? 'zero' : '') + '" style="width:' + job.percent_complete + '%;"></div><div class="percent_complete">' + job.percent_complete + '%</div><div class="job_id">#' + job.id + '</div></div>');
  },
  
  // Animate the update to an existing job in the queue.
  updateJob : function(job, jobEl) {
    jobEl.animate({width : job.width + '%'}, this.ANIMATION_SPEED);
    var completion = $('.completion', jobEl);
    if (job.percent_complete > 0) completion.removeClass('zero');
    completion.animate({width : job.percent_complete + '%'}, this.ANIMATION_SPEED);
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
  // This method is desperately in need of Javascript templates...
  renderNodes : function() {
    var header = $('#sidebar_header');
    var nc = this._nodes.length, wc = this._workerCount;
    $('.has_nodes', header).html(nc + " Node" + (nc != 1 ? 's' : '') + " / " + wc + " Worker" + (wc != 1 ? 's' : ''));
    header.toggleClass('no_nodes', this._nodes.length <= 0);
    $('#nodes').html($.map(this._nodes, function(node) { 
      var html = "";
      var extra = node.status == 'busy' ? ' <span class="busy">[busy]</span>' : '';
      html += '<div class="node ' + node.status + '">' + node.host + extra + '</div>';
      html += $.map(node.workers, function(pid) {
        var name = pid + '@' + node.host;
        return '<div class="worker" rel="' + name + '">' + name + '</div>';
      }).join('');
      return html;
    }).join(''));
  },
  
  // Record the current state and re-render all graphs.
  recordDataPoint : function() {
    var timestamp = (new Date()).getTime();
    this._jobsHistory.push([timestamp, this._jobs.length]);
    this._nodesHistory.push([timestamp, this._nodes.length]);
    this._workersHistory.push([timestamp, this._workerCount]);
    this._workUnitsHistory.push([timestamp, this._workUnitCount]);
    $.each(this._histories, function() { 
      if (this.length > Console.MAX_DATA_POINTS) this.shift(); 
    });
  },
  
  // Convert our recorded data points into a format Flot can understand.
  renderGraphs : function() {
    $.plot($('#work_units_graph'), [
      {label : 'Work Units in Queue', color : Console.WORK_UNITS_COLOR, data : Console._workUnitsHistory}
    ], Console.GRAPH_OPTIONS);
    $.plot($('#jobs_graph'), [
      {label : 'Jobs in Queue', color : Console.JOBS_COLOR, data : Console._jobsHistory}
    ], Console.GRAPH_OPTIONS);
    $.plot($('#workers_graph'), [
      {label : 'Nodes', color : Console.NODES_COLOR, data : Console._nodesHistory},
      {label : 'Workers', color : Console.WORKERS_COLOR, data : Console._workersHistory}
    ], Console.GRAPH_OPTIONS);
  },
  
  // Request the Worker info from the central server.
  getWorkerInfo : function(e) {
    e.stopImmediatePropagation();
    var info = Console._workerInfo;
    var row = $(this);
    info.addClass('loading');
    $.get('worker/' + row.attr('rel'), null, Console.renderWorkerInfo, 'json');
    info.css({top : row.offset().top, left : 325});
    info.fadeIn(Console.ANIMATION_SPEED);
    $(document).bind('click', Console.hideWorkerInfo);
    return false;
  },
  
  // When we receieve worker info, update the bubble.
  renderWorkerInfo : function(resp) {
    var info = Console._workerInfo;
    info.toggleClass('awake', !!resp.status);
    info.removeClass('loading');
    if (!resp.status) return;
    $('.status', info).html(Console.DISPLAY_STATUS_MAP[resp.status]);
    $('.action', info).html(resp.action);
    $('.job_id', info).html(resp.job_id);
    $('.work_unit_id', info).html(resp.id);
  },
  
  // Hide worker info and unbind the global hide handler.
  hideWorkerInfo : function() {
    $(document).unbind('click', Console.hideWorkerInfo);
    Console._workerInfo.fadeOut(Console.ANIMATION_SPEED); 
  }
  
};

$(document).ready(function() { Console.initialize(); });