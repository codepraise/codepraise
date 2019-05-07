window.onload = function(){
  if (in_path('root')) {
    console.log('In the root path.')
    search_btn = document.getElementById('search-btn')
    search_btn.addEventListener('click', search_project)
  }

  if (in_path('appraisal')) {
    console.log('In the appraisal path.')
    folder_menu()
    charts = create_all_chart()
    main_chart = charts.find((chart) =>{
      return chart.id == 'main'
    })
    main_chart.canvas.addEventListener('click', function(e){
        eventElement = charts[1].chart.getElementAtEvent(e)[0]

        if(eventElement == undefined) return;

        label = charts[1].chart.data.labels[eventElement._index]
        number = parseInt(eventElement._index)
        console.log(number)
        update(charts, number)
    });

  }
}