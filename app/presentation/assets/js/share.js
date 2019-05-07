function ajax_call(url, method, data, sucecss_callback){
  $.ajax({
    url: url,
    method: method,
    data: data,
    success: sucecss_callback
  });
}

function in_path(path){
  return document.getElementById(path) != null;
}

function project_element(project) {
  return `<div class="card bg-info clickable" id="${project['fullname']}">
    <div class="card-body">
      <p class="card-title">${project['name']}</p>
      <p class="card-subtitle">${project['owner']['username']}</p>
    </div>
  </div>`
}

function progessing(bar, percentage, callback) {
  progress_number = percentage;
  current_progress = parseInt(/(\d+)/.exec(bar.style.width)[0]);
  if (isNaN(percentage)) progress_number = parseInt(percentage);

  if (progress_number > current_progress && progress_number <= 100){
    bar.setAttribute("style", `width:${progress_number}%`)
  }

  if (percentage == 100){
    return callback();
  }
}

function create_all_chart(){
  charts_element = document.querySelectorAll('.chart canvas')
  charts = Array.from(charts_element).map(chart => {
    if (chart == undefined) return;

    customChart = new CustomChart(chart.id);
    customChart.render();
    return customChart;
  });

  return charts;
}

var test

function update(charts, number){
  main = document.querySelector('.main')
  owner_name = main.dataset.owner
  project_name = main.dataset.project
  category = main.dataset.category

  test = (data) => {
    data = JSON.parse(data)['charts']
    charts.forEach(chart => {
      chart_data = data[chart.canvas.dataset.title]

      if (chart_data){
        test = chart_data
        chart.canvas.dataset.labels = JSON.stringify(chart_data['labels']);
        chart.canvas.dataset.values = JSON.stringify(chart_data['dataset']);
        chart.update();
        console.log(chart.canvas.dataset)
      }
    });
  }
  ajax_call(`/appraisal/${owner_name}/${project_name}?category=${category}&type=json&number=${number}`, 'GET', null, test)
}