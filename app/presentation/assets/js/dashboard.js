function folder_menu(){
  folders = document.querySelectorAll('.folder');
  folders.forEach(function(folder){
    caret = folder.querySelector('.caret')
    caret.addEventListener('click', function(){
      children = this.parentElement.querySelector('.children');
      if (children.classList.contains('active')){
        this.classList.remove('caret-down')
        children.classList.remove('active');
      }else{
        this.classList.add('caret-down')
        children.classList.add('active');
      }
    });
  });
  return true;
}


function change_page(){
  page = document.querySelector('.page');
  categories = document.querySelectorAll('.category');
  categories.forEach(function(category){
    if (category.id != `${page.id}_page`){
      category.classList.remove('selected')
    }else{
      category.classList.add('selected')
    }
  });
}

function update_message(data){
  message = document.querySelector('.content .alert')
  message.querySelector('span').textContent = JSON.parse(data)['message']
  message.classList.remove('hidden');

  button = message.querySelector('button')
  button.addEventListener('click', function(){
    message.classList.add('hidden');
  });
}

function update_buttob(){
  updateBtn = document.querySelector('.dropdown #update')
  updateBtn.addEventListener('click', function(){
    main = document.querySelector('.main')
    project_name = main.dataset.project
    owner_name = main.dataset.owner
    console.log(`p: ${project_name}, o: ${owner_name}`)
    ajax_call(`/appraisal/${owner_name}/${project_name}`, 'PUT', null, update_message)
  })
}

