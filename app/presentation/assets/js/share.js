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

function create_all_chart(){
  charts_element = document.querySelectorAll('.element canvas')
  charts = Array.from(charts_element).map(chart => {
    if (chart == undefined) return;

    customChart = new CustomChart(chart.id);
    customChart.render();
    return customChart;
  });
  treemaps_element = document.querySelectorAll('.treemap')
  treemaps = Array.from(treemaps_element).map(chart => {
    treemap = new TreeMap(chart.id)
    treemap.render()
    return treemap
  });
  return charts.concat(treemaps);
}

function update(charts, arg){
  main = document.querySelector('.main')
  owner_name = main.dataset.owner
  project_name = main.dataset.project
  category = main.dataset.category
  url = `/appraisal/${owner_name}/${project_name}?category=${category}&type=json&${arg}`
  tables = document.querySelectorAll('table')

  // update_board_title = (element, title) => {
  //   board_title = element.parentNode.parentNode.parentNode.querySelector('.board-title')
  //   board_title.querySelector('.title').textContent = title
  // };

  update_charts = (data) => {
    data = JSON.parse(data)['elements']
    test = data
    console.log(data)
    charts.forEach(chart => {
      chart_data = chart.canvas ? data[chart.canvas.id] : null
      if (chart_data){
        chart.canvas.dataset.labels = JSON.stringify(chart_data['labels']);
        chart.canvas.dataset.values = JSON.stringify(chart_data['dataset']);
        chart.canvas.dataset.options = JSON.stringify(chart_data['options'])
        chart.update();
        if (chart_data['title']){
          // update_board_title(chart.canvas, chart_data['title'])
        }
        console.log(chart.canvas.dataset)
      }
    });
    tables.forEach(table => {
      table_data = data[table.id]
      if (table_data){
        table_obj = new Table(table.id)
        table_obj.update(table_data['tbody'])
        if (table_data['title']){
          update_board_title(table_obj.table, table_data['title'])
        }
      }
    });
  };
  ajax_call(url, 'GET', null, update_charts)
}

function change_chart(event){
  board_element = event.path.find((e) => {
    return e.classList.contains('a-board') || e.classList.contains('b-board');
  })
  chart_elements = board_element.querySelectorAll('.element');
  chart_elements.forEach(chart => {
    if(chart.classList.contains('hidden')){
      chart.classList.remove('hidden');
    }else{
      chart.classList.add('hidden');
    }
  });
}

Table = function(id) {
  this.table = document.getElementById(id);
  this.tbody = this.table.querySelector('tbody')
  this.rows = this.tbody.querySelectorAll('tr');
}

Table.prototype.row_element = function(values){
  return `<tr> ${values.map(value => `<td>${value}</td>`).join('')} </tr>`
}

Table.prototype.update = function(data){
  tbody =  data.map(this.row_element).join('');
  this.tbody.innerHTML = tbody;
}

Date.prototype.addDays = function(days) {
  this.setDate(this.getDate() + days);
  return this;
}

Date.prototype.removeDays = function(days) {
  this.setDate(this.getDate() - days);
  return this;
}

Date.prototype.getDateString = function(){
  date = this.getDate();
  month = this.getMonth() + 1;
  year = this.getUTCFullYear();
  return `${year}/${month}/${date}`
}
