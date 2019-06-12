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
}

Axex.prototype.render = function(){
  ticks = { fontSize: 16 }
  if(this.ticked){
    ticks = {
      suggestedMax: this.max,
      suggestedMin: this.min,
      fontSize: 16,
      reverse: this.reverse,
      beginAtZero: this.beginAtZero
    }
  }
  return [{
    stacked: this.stacked,
    type: this.type,
    display: true,
    time: this.time,
    gridLines: {
      display: this.gridline
    },
    scaleLabel: {
      display: this.label,
      labelString: this.label_string,
      fontSize: 16
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
      tooltips: tooltips
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
  colors = {
    contributors: ['rgba(33, 85, 164, 0.5)', 'rgba(254, 184, 73, 0.5)', 'rgba(40, 183, 122, 0.5)', 'rgba(39, 169, 227, 0.5)', 'rgba(218, 84, 46, 0.5)'],
    category: ['rgba(33, 85, 164,0.8)', 'rgba(33, 85, 164,0.2)'],
    gradient: ['rgba(63,73,88)', 'rgba(63,73,88,0.7)', 'rgba(63,73,88,0.4)', 'rgba(63,73,88, 0.2)'],
    category_border: ['rgba(63,73,88)', 'rgba(63,73,88,0.2)'],
    contributors_border: ['rgba(33, 85, 164)', 'rgba(254, 184, 73)', 'rgba(40, 183, 122)', 'rgba(39, 169, 227)', 'rgba(218, 84, 46)'],
    same: fillArray('rgba(33, 85, 164, 0.5)', 100),
    same_border: fillArray('rgba(33, 85, 164)', 100)
  }
  return colors[type]
}
