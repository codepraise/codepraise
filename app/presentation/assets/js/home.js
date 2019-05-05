function search_project(){

  function add_project_card(data){
    projects = document.querySelector('.projects')
    projects.insertAdjacentHTML( 'beforeend', project_element(JSON.parse(data)) );
  }

  const project_url = document.querySelector('.search-bar input').value
  const data = {
    remote_url: project_url
  }
  ajax_call('/project', 'POST', data, add_project_card)
}