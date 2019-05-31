var CustomChart = function(canvas_id){

  const main_color = '63,73,88'
  // const main_color = '14, 160, 204'
  const gradient_color = [`rgba(${main_color})`, `rgba(${main_color},0.7)`, `rgba(${main_color},0.4)`, `rgba(${main_color},0.2)`]
  const colorful = [`rgba(42,50,57,0.8)`, `rgba(42,50,57,0.2)`]
  const same_color = []
  for(var i = 0; i<10; i++){
    same_color.push(`rgba(${same_color})`)
  }

  this.render_dataset = function dataset(dataset){
    let result = []
    let index = 0
    let values = JSON.parse(dataset.values)
    custom_options = (dataset.options == '' ? {} : JSON.parse(dataset.options));
    color = gradient_color
    if (custom_options['color'] == 'colorful'){ color = colorful }
    if (custom_options['color'] == 'main'){color = same_color}
    if (values instanceof(Array)){
      result = [{
        data: values,
        borderWidth: 1,
        backgroundColor: color
      }]
    }else{
      Object.keys(values).forEach( key => {
        result.push(
          {
            label: key,
            fill: false,
            backgroundColor: color[index],
            borderColor: color[index],
            borderWidth: 2,
            data: values[key]
          }
        )
        index += 1
      })
    }

    return result
  }

  this.id = canvas_id

  this.canvas = document.getElementById(canvas_id)

  this.type = this.canvas.dataset.type

  this.data = {
    labels: JSON.parse(this.canvas.dataset.labels),
    datasets: this.render_dataset(this.canvas.dataset)
  }

  this.options = function(custom_options){
    options = Options
    custom_options = (custom_options == '' ? {} : JSON.parse(custom_options));
    options.gridline = custom_options['gridline'] || false;
    options.stacked = custom_options['stacked'] || false;
    options.title = custom_options['title'] || 'Chart Title';
    options.legend = custom_options['legend'] || false;
    options.xAxex.position = custom_options['x_position'] || 'bottom'
    options.xAxex.type = custom_options['x_type'] || 'category'
    if(custom_options['x_type'] == 'time'){
      options.xAxex.time = {unit: custom_options['time_unit']}
    }
    options.xAxex.label = custom_options['axes_label'] || false
    options.xAxex.label_string = custom_options['x_label'] || ''
    options.yAxex.type = custom_options['y_type'] || 'linear'
    options.yAxex.label = custom_options['axes_label'] || false
    options.yAxex.label_string = custom_options['y_label'] || ''
    options.yAxex.position = custom_options['y_position'] || 'left'
    options.yAxex.ticked = custom_options['y_ticked'] || false
    options.yAxex.min = custom_options['y_min'] || 0
    options.yAxex.max = custom_options['y_max'] || 1000
    if (custom_options['tooltips'] == 'file_churn'){
      options.callback = {
        label: function(tooltipItem, data){
          index = tooltipItem.index
          dataset = data.datasets[0].data
          title = dataset[index]['title']
          commits = dataset[index]['x']
          complexity = dataset[index]['y']
          message = [
            [`file: ${title}`],
            [`commits: ${commits}`],
            [`complexity: ${complexity}`]
          ]
          return message
        }
      }
    }else{
      options.callback = {};
    }
    return options.render()
  }
}

CustomChart.prototype.render = function(){
  this.chart = new Chart(this.canvas, {
    type: this.type,
    data: this.data,
    options: this.options(this.canvas.dataset.options)
  });
  console.log(this.options(this.canvas.dataset.options))
}

CustomChart.prototype.update = function(){
  if (this.canvas == undefined) return;

  this.type = this.canvas.dataset.type

  this.data = {
    labels: JSON.parse(this.canvas.dataset.labels),
    datasets: this.render_dataset(this.canvas.dataset)
  }
  this.chart.destroy();

  this.render();
}


function test(p){
}

var TreeMap = function(canvas_id){
  this.id = canvas_id
  this.canvas = document.getElementById(canvas_id)
  this.series = JSON.parse(this.canvas.dataset.values)
  this.title =
  this.config = function(series){
    return {
      graphset: [
        {
          type: "treemap",
          title: {
            text: "Please include coverage/.result.set.json in your repo"
          },
          options: {
            "aspect-type": "transition",
            "color-start": "#B5B8BD",
            "color-end": '#3F4958',
            "max-children": [30, 30, 30],
            "max-depth": 10
          },
          globals:{
            fontSize: 16
          },
          series: series
        }
      ]
    }
  }
};


TreeMap.prototype.render = function(){
  this.chart = zingchart.render({
    id: this.id,
    data: this.config(this.series),
    height: "100%",
    width: "100%"
  })
}

TreeMap.prototype.update = function(){
  if (this.canvas == undefined) return;

  this.series = JSON.parse(this.canvas.dataset.values);
  this.chart.clear()
  this.render()
}
