var CustomChart = function(canvas_id, stacked=false, title='Chart Title'){

  const color = '75, 177, 209'
  const background_color = [`rgba(${color},0.8)`, `rgba(${color},0.5)`, `rgba(${color},0.2)`]
  const border_color = [`rgba(${color},0.8)`, `rgba(${color},0.8)`, `rgba(${color},0.8)`]

  this.id = canvas_id

  this.render_dataset = function dataset(hash){
    const result = []
    let index = 0
    Object.keys(hash).forEach( key => {
      result.push(
        {
          label: key,
          fill: false,
          backgroundColor: background_color[index],
          borderColor: border_color[index],
          borderWidth: 2,
          data: hash[key]
        }
      )
      index += 1
    })
    return result
  }

  this.canvas = document.getElementById(canvas_id)

  // var observer = function(obj){

  //   var mutationObserver = new MutationObserver(function(mutations) {
  //     mutations.forEach(function(mutation) {
  //       if (mutation.type == "attributes") {
  //         obj.update()
  //       }
  //     });
  //   });

  //   mutationObserver.observe(obj.canvas, {
  //     attributes: true
  //   });
  // }

  // observer(this)

  this.type = this.canvas.dataset.type

  this.data = {
    labels: JSON.parse(this.canvas.dataset.labels),
    datasets: this.render_dataset(JSON.parse(this.canvas.dataset.values))
  }
  this.options = {
    maintainAspectRatio: false,
    title: {
      display: true,
      text: title
    },
    legend: {
      display: true,
      position:'bottom'
    },
    tooltips: {
      mode: 'label',
      label: 'mylabel',
      callbacks: {
          label: function (tooltipItem, data) {
              return tooltipItem.yLabel.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
          }}
    },
    scales: {
      yAxes: [{
        stacked: stacked,
        ticks: {
          suggestedMin: 0
        },
        gridLines: {
          display: false,
          color: "rgba(255,99,132,0.2)"
        }
      }],
      xAxes: [{
        stacked: stacked,
        // type: 'time',
        // time:{
        //   unit: 'day'
        // },
        gridLines: {
          display: false
        }
      }]
    }
  }
}

CustomChart.prototype.render = function(){
  this.chart = new Chart(this.canvas, {
    type: this.type,
    data: this.data,
    options: this.options
  });
}

CustomChart.prototype.update = function(){
  if (this.canvas == undefined) return;

  this.type = this.canvas.dataset.type

  this.data = {
    labels: JSON.parse(this.canvas.dataset.labels),
    datasets: this.render_dataset(JSON.parse(this.canvas.dataset.values))
  }
  this.chart.destroy();

  this.render();
}