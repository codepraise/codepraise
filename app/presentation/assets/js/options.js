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
}

Axex.prototype.render = function(){
  ticks = { fontSize: 16 }
  if(this.ticked){
    ticks = {
      suggestedMax: this.max,
      suggestedMin: this.min,
      fontSize: 16
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
