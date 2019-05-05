function ajax_call(url, method, data, sucecss_callback){
  $.ajax({
    url: url,
    method: method,
    data: data,
    success: sucecss_callback
  });
}

function in_path(path){
  return document.getElementById(path) != null;
}

function project_element(project) {
  return `<div class="card bg-info clickable" id="${project['fullname']}">
    <div class="card-body">
      <p class="card-title">${project['name']}</p>
      <p class="card-subtitle">${project['owner']['username']}</p>
    </div>
  </div>`
}

function progessing(bar, percentage, callback) {
  progress_number = percentage;
  current_progress = parseInt(/(\d+)/.exec(bar.style.width)[0]);
  if (isNaN(percentage)) progress_number = parseInt(percentage);

  if (progress_number > current_progress && progress_number <= 100){
    bar.setAttribute("style", `width:${progress_number}%`)
  }

  if (percentage == 100){
    return callback();
  }
}