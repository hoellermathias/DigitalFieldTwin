function send_it(ret) {
  const data = window.top.sessionStorage
  console.log('data', data)
  console.log('data', ret)

  parent.sendCallback(window.frameElement.id, JSON.stringify({...ret, ...data}))
  window.top.sessionStorage.clear()
}
function store_it(key, val){
  var store = window.top.sessionStorage
  store.setItem(key, val)
}
function get_data(key){
  console.log(window.top.sessionStorage)
  console.log(`cpee-${key}`)
  try{return JSON.parse(window.top.sessionStorage.getItem(`cpee-${key}`))}catch(e){return window.top.sessionStorage[`cpee-${key}`]}
}
function load_dataelements(){
  $.each(window.top.sessionStorage, (key, val) => {key = key.slice(0, "cpee-".length-1); key === "cpee-" && window.top.sessionStorage.removeItem(key)})
  $.ajax({
    type: "GET",
    url: window.top.location.href + 'dataelements.json',
    success: function(ret) {
      console.log(ret)
      JSON.parse(ret[0]['data']).forEach(function(e){
        console.log('aaaaa', e)
        window.top.sessionStorage.setItem(`cpee-${Object.keys(e)[0]}`, JSON.stringify(Object.values(e)[0]))
      })
      const event = new Event('data_load_end');
      window.top.dispatchEvent(event);
    },
    error: function(ret){
      window.top.sessionStorage.setItem('cpee-data', ret)
    }
  });
}

function display_data(){
  Object.keys(window.top.sessionStorage).forEach(function(name){
    const value = window.top.sessionStorage.getItem(name)
    console.log("AAAAA", value, name)
    $("#"+name.slice("cpee-".length)).html(JSON.parse(value));
  });
}
