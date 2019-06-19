Axex = function(){
  this.gridline = false,
  this.stacked = false,
  this.label = false,
  this.label_string = '',
  this.type = 'linear',
  this.time = {},
  this.position = ''
  this.ticked = false
  this.min = 0
  this.max = 0
  this.reverse = false
  this.stepSize = 10
  this.beginAtZero = true
  this.display = true
}

Axex.prototype.render = function(){
  ticks = { fontSize: 14 }
  if(this.ticked){
    ticks = {
      suggestedMax: this.max,
      suggestedMin: this.min,
      fontSize: 14,
      reverse: this.reverse,
      beginAtZero: this.beginAtZero
    }
  }
  return [{
    stacked: this.stacked,
    type: this.type,
    display: this.display,
    time: this.time,
    gridLines: {
      display: this.gridline
    },
    scaleLabel: {
      display: this.label,
      labelString: this.label_string,
      fontSize: 14
    },
    position: this.position,
    ticks: ticks
  }]
}

Options = {
  callback: {},
  stacked: false,
  xAxex: new Axex(),
  yAxex: new Axex(),
  gridline: false,
  pointStyle: 'circle',
  title: 'Chart Title',
  title_size: 16,
  legend: false,
  scale: function(){
    this.xAxex.stacked = this.stacked
    this.xAxex.gridline = this.gridline
    this.yAxex.stacked = this.stacked
    this.yAxex.gridline = this.gridline
    return {
      xAxes: this.xAxex.render(),
      yAxes: this.yAxex.render()
    }
  },
  render: function(){
    tooltips = { callbacks: this.callback }
    scales = this.scale()
    return {
      responsive: true,
      maintainAspectRatio: false,
      title: {
        display: true,
        text: this.title,
        fontSize: this.title_size
      },
      legend: {
        display: this.legend,
        position: 'bottom',
        labels: {
          fontSize: 16
        }
      },
      scales: scales,
      tooltips: tooltips,
      elements: {
        point: {
          pointStyle: this.pointStyle
        }
      }
    }
  }
}

function fillArray(value, len) {
  if (len == 0) return [];
  var a = [value];
  while (a.length * 2 <= len) a = a.concat(a);
  if (a.length < len) a = a.concat(a.slice(0, len - a.length));
  return a;
}

function getColor(type){
  type_array = type.split('_')
  type = type_array[0]
  index = parseInt(type_array[1]);
  colors = {
    contributors: ['rgba(33, 85, 164, 0.5)', 'rgba(254, 184, 73, 0.5)', 'rgba(40, 183, 122, 0.5)', 'rgba(39, 169, 227, 0.5)', 'rgba(218, 84, 46, 0.5)'],
    category: ['rgb(73, 73, 73, 0.8)', 'rgba(73, 73, 73,0.2)'],
    gradient: ['rgba(63,73,88)', 'rgba(63,73,88,0.7)', 'rgba(63,73,88,0.4)', 'rgba(63,73,88, 0.2)'],
    category_border: ['rgb(73, 73, 73, 0.8)', 'rgba(73, 73, 73,0.2)'],
    contributors_border: ['rgba(33, 85, 164)', 'rgba(254, 184, 73)', 'rgba(40, 183, 122)', 'rgba(39, 169, 227)', 'rgba(218, 84, 46)'],
    same: fillArray('rgb(73, 73, 73, 0.5)', 100),
    same_border: fillArray('rgb(73, 73, 73)', 100),
    multiple: [['rgba(33, 85, 164, 0.8)', 'rgba(33, 85, 164, 0.2)'], ['rgba(254, 184, 73, 0.8)',  'rgba(254, 184, 73, 0.2)'],
               ['rgba(40, 183, 122, 0.8)',  'rgba(40, 183, 122, 0.2)'], ['rgba(39, 169, 227, 0.8)',  'rgba(39, 169, 227, 0.2)'],
               ['rgba(254, 184, 73, 0.5)',  'rgba(254, 184, 73, 0.3)']],
    multiple_border: [['rgba(33, 85, 164, 0.8)', 'rgba(33, 85, 164, 0.2)'], ['rgba(254, 184, 73, 0.8)',  'rgba(254, 184, 73, 0.2)'],
    ['rgba(40, 183, 122, 0.8)',  'rgba(40, 183, 122, 0.2)'], ['rgba(39, 169, 227, 0.8)',  'rgba(39, 169, 227, 0.2)'],
    ['rgba(254, 184, 73, 0.5)',  'rgba(254, 184, 73, 0.3)']]
  }
  color = colors[type]
  if(index || index >= 0){
    color = colors[type][index]
  }
  return color
}
