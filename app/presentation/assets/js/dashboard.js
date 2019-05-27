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

