var CustomChart = function(canvas_id){

  this.render_dataset = function dataset(dataset){
    let result = []
    let index = 0
    let values = JSON.parse(dataset.values)
    custom_options = (dataset.options == '' ? {} : JSON.parse(dataset.options));
    color = getColor(custom_options['color'])
    if (values instanceof(Array)){
      if (custom_options['multiple']){
        values.forEach( dataset => {
          j = 0
          Object.keys(dataset).forEach( key => {
            result.push(
              {
                label: key,
                fill: false,
                backgroundColor: color[index][j],
                borderColor: color[index][j],
                borderWidth: 2,
                data: dataset[key]
              }
            )
            j += 1;
          })
          index += 1;
        })
      }else{
        result = [{
          data: values,
          borderWidth: 1,
          backgroundColor: color
        }]
      }
    }else{
      Object.keys(values).forEach( key => {
        result.push(
          {
            label: key,
            fill: false,
            backgroundColor: color[index],
            borderColor: getColor(`${custom_options['color']}_border`)[index],
            borderWidth: 2,
            data: values[key]
          }
        )
        index += 1
      })
    }
    if (custom_options['line']){
      background_color = 'rgb(247, 77, 78, 0.1)'
      border_color = 'rgb(247, 77, 78)'
      fill = 'start'
      label = 'dangerous zone'
      if (custom_options['title'] == 'test contribution'){
        background_color = 'rgb(77, 247, 78, 0.1)'
        border_color = 'rgb(77, 247, 78)'
        fill = 'none'
        label = 'ideal curve'
      }
      result.push({
        data: custom_options['line']['data'],
        type: 'line',
        backgroundColor: background_color,
        borderWidth: 2,
        borderColor: border_color,
        fill: fill,
        label: label
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
    options.pointStyle = custom_options['point'] || 'circle';
    options.xAxex.position = custom_options['x_position'] || 'bottom'
    options.xAxex.type = custom_options['x_type'] || 'category'
    options.xAxex.ticked = true
    options.xAxex.min = custom_options['x_min'] || 0
    options.xAxex.max = custom_options['x_max'] || 0
    options.xAxex.display = (custom_options['x_display'] == 0 ? false : true)
    options.xAxex.stepSize = custom_options['x_step'] || 10
    if(custom_options['x_type'] == 'time'){
      options.xAxex.time = {unit: custom_options['time_unit']}
    }
    options.xAxex.label = (custom_options['x_label'] ? true : false)
    options.xAxex.label_string = custom_options['x_label'] || ''
    options.yAxex.reverse = custom_options['y_reverse'] || false
    options.yAxex.type = custom_options['y_type'] || 'linear'
    options.yAxex.label = (custom_options['y_label'] ? true : false)
    options.yAxex.label_string = custom_options['y_label'] || ''
    options.yAxex.position = custom_options['y_position'] || 'left'
    options.yAxex.ticked = true
    options.yAxex.min = custom_options['y_min'] || 0
    options.yAxex.max = custom_options['y_max'] || 0
    options.yAxex.stepSize = custom_options['y_step'] || 10
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

var TreeMap = function(canvas_id){
  this.id = canvas_id
  this.canvas = document.getElementById(canvas_id)
  this.series = JSON.parse(this.canvas.dataset.values)
  this.options = JSON.parse(this.canvas.dataset.options)
  this.config = function(series, options){
    color_start = '#28B77A'
    color_end = '#ff7a7b'
    if (options['reverse']){
      temp = color_start
      color_start = color_end
      color_end = temp
      console.log('test')
    }
    console.log(color_start)
    return {
      graphset: [
        {
          type: "treemap",
          options: {
            "aspect-type": "transition",
            "color-start": color_start,
            "color-end": color_end,
            "max-children": [30, 30, 30],
            "max-depth": 10
            // "tooltip-box":{
            //   "text":`%text`
            // }
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
    data: this.config(this.series, this.options),
    height: "100%",
    width: "100%"
  })
}

TreeMap.prototype.update = function(){
  if (this.canvas == undefined) return;

  this.series = JSON.parse(this.canvas.dataset.values);
  this.options = JSON.parse(this.canvas.dataset.options);
  this.chart.clear()
  this.render()
}
