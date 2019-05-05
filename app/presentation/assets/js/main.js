window.onload = function(){
  if (in_path('root')) {
    console.log('In the root path.')
    search_btn = document.getElementById('search-btn')
    search_btn.addEventListener('click', search_project)
  }

  if (in_path('appraisal')) {
    console.log('In the appraisal path.')
    folder_menu()
    commitsChart = new CustomChart('commits_chart');
    commitsChart.render();
    test = new CustomChart('test');
    test.render();
  }
}