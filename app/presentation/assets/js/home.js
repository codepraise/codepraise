function build_project_element(project) {
  return `<div class="card bg-dark" id="${project['fullname']}">
    <div class="card-body">
      <a href="/appraisal/${project['owner']['username']}/${project['name']}">
        <p class="card-title">${project['name']}</p>
        <p class="card-subtitle">${project['owner']['username']}</p>
      </a>
    </div>
  </div>`
}

function search_project(){

  let alert = document.querySelector('.flash .alert')
  const project_url = document.querySelector('.search-bar input').value

  alert.querySelector('span').textContent = 'Searching...'
  alert.classList.remove('hidden')


  if (project_url == ""){
    alert.querySelector('span').textContent = "Input value can't be empty."
    alert.classList.remove('hidden')
    return
  }

  if (check_project_exist(project_url)){
    alert.querySelector('span').textContent = 'Project already exists'
    alert.classList.remove('hidden')
    return
  }


  function add_project_card(data){
    projects = document.querySelector('.projects')
    projects.insertAdjacentHTML( 'beforeend', build_project_element(JSON.parse(data)) );
    alert.querySelector('span').textContent = 'Project is ready.'
    document.querySelector('.search-bar input').value = ''
  }

  const data = {
    remote_url: project_url
  }
  ajax_call('/project', 'POST', data, add_project_card)
}

function check_project_exist(project_url){
  project_fullname = project_url.replace('.git', '').split('/').slice(-2).join('/')
  project_element = document.getElementById(project_fullname)
  return (project_element != null)
}


