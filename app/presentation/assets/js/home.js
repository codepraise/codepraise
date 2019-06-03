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
  alert.classList.add('alert-warning')
  alert.classList.remove('alert-danger')
  alert.querySelector('span').textContent = 'Searching...'
  alert.classList.remove('hidden')

  project_cards = document.querySelectorAll('.projects .card')
  project_cards.forEach(card => {
    card.classList.remove('bg-info')
    card.classList.add('bg-dark')
  });
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
    data = JSON.parse(data)
    if (data['message']){
      alert = document.querySelector('.flash .alert')
      alert.classList.remove('alert-warning')
      alert.classList.add('alert-danger')
      alert.querySelector('span').textContent = 'Bad Github Url'
      console.log('test')
    }else{
      projects = document.querySelector('.projects')
      projects.insertAdjacentHTML( 'beforeend', build_project_element(data) );
      alert.querySelector('span').textContent = 'Project is ready.'
      document.querySelector('.search-bar input').value = ''
    }
  }

  const data = {
    remote_url: project_url
  }
  ajax_call('/project', 'POST', data, add_project_card)
}

function check_project_exist(project_url){
  project_fullname = project_url.replace('.git', '').split('/').slice(-2).join('/')
  project_element = document.getElementById(project_fullname)
  project_element.classList.remove('bg-dark')
  project_element.classList.add('bg-info')
  return (project_element != null)
}


