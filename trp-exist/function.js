function highlight ( line ) {
  const atDataStyle = line.getAttribute("data-style")
      , text = line.textContent;
  
  if ( atDataStyle != "" ) {
    let styleValues = atDataStyle.split('} textStyle {')
      , styleList = [];
    
    for ( let style of styleValues ) {
      let parts = style.split(';')
        , values = {};
      
      for ( let part of parts ) {
        let i = part.split(':');
        if ( i != "" ) {
          values[i[0].trim()] = i[1].trim();
        }
      }

      styleList.push(values);
    }

    let htmlContent = "";
    for ( let i = 0; i < styleList.length; i++ ) {
      let values = styleList[i]
        , styleString = "";

      if ( values.hasOwnProperty('italic') ) styleString += "font-style: italic;";
      if ( values.hasOwnProperty('bold') ) styleString += "font-weight: bold;";
      if ( values.hasOwnProperty('superscript') ) styleString += "vertical-align: super;";
      
      let prevStart = i == 0 ? 0 : styleList[i-1].offset
        , prevLength = i == 0 ? 0 : styleList[i-1].length
        , prevEnd = parseInt(prevStart) + parseInt(prevLength)
        , before = text.slice(prevEnd, parseInt(values.offset))
        , inner = text.slice(parseInt(values.offset), (parseInt(values.offset) + parseInt(values.length)));
        
      htmlContent += `${before}<span style="${styleString}">${inner}</span>`;
    }

    let afterStart = parseInt(styleList[styleList.length - 1].offset) + parseInt(styleList[styleList.length - 1].length);
    htmlContent += text.slice(afterStart);

    line.innerHTML = htmlContent;
  }
}
window.addEventListener('DOMContentLoaded', function () {
  const searchParams = new URLSearchParams(window.location.search);

  document.getElementById('login-form')?.addEventListener('submit', ( event ) => {
    event.preventDefault();
  
    let user = event.target?.[0].value
      , pass = event.target?.[1].value;

    let req = new XMLHttpRequest();
    req.onload = () => {
      if ( req.status != 200 ) {
        document.getElementById('login-info').innerHTML = "Login failed";
      } else {
        let token = req.response;
        window.location.href = "collections.html?sessionId=" + token;
      }
    }

    let url = new URL('/exist/restxq/trpex/login', window.location.href);
    url.searchParams.set('user', user);
    url.searchParams.set('pass', pass);
    req.open('GET', url);
    req.send();
  });

  if ( window.location.pathname.endsWith("collections.html") ) {
    let listsUrl;
    if ( searchParams.has('collection') ) {
      listsUrl = new URL('/exist/restxq/trpex/collections/' + searchParams.get('collection') + '/list', window.location.href);
    } else {
      listsUrl = new URL('/exist/restxq/trpex/collections', window.location.href);
    }
    
    listsUrl.searchParams.set("sessionId", searchParams.get('sessionId'));

    let req = new XMLHttpRequest();
    req.onload = () => {
      if ( req.status != 200 ) {
        console.log("error: ", req.response);
        document.getElementById('collection-info').innerHTML = "Error getting info";
      } else {
        document.getElementById('collection').innerHTML = req.responseText;
      }
    }
    req.open('GET', listsUrl);
    req.send();
  } else if ( window.location.pathname.endsWith("compare.html") ) {
    let url = '/exist/restxq/trpex/collections/'
            + searchParams.get('collection') + '/'
            + searchParams.get('document') + '/info';
    let mdUrl = new URL(url, window.location.href)
      , mdReq = new XMLHttpRequest();
    mdReq.onload = () => {
      if ( mdReq.status == 200 ) {
        let mdResponse = JSON.parse(mdReq.response);
        document.getElementById('comparison-info').outerHTML = '<div>\
        <h1>' + mdResponse.md.title + ' (' + mdResponse.collection.colName + ')</h1>\
        <p><a href="collections.html?sessionId=' + searchParams.get('sessionId')
          + '&collection=' + searchParams.get('collection')
          + '">back to document list</a></p>\
        </div>';
      } else {
        console.log(req.response);
      }
    }
    mdReq.open("GET", mdUrl);
    mdReq.send();

    let page = searchParams.has('page') ? searchParams.get('page') : 1;
    url = '/exist/restxq/trpex/compare/'
          + searchParams.get('collection') + '/'
          + searchParams.get('document') + '/'
          + page + '/latest';
    
    let compareUrl = new URL(url, window.location.href);
    compareUrl.searchParams.set("sessionId", searchParams.get('sessionId'));

    let req = new XMLHttpRequest();
    req.onload = () => {
      if ( req.status != 200 ) {
        console.log("error: ", req.response);
        document.getElementById('comparison-info').innerHTML = "Error getting info";
      } else {
        document.getElementById('comparison').innerHTML = req.responseText;
      }
    }
    req.open('GET', compareUrl);
    req.send();
  }

  if ( document.getElementsByClassName("lineok") != undefined ) {
    const lines = document.getElementsByClassName("lineok");
    for ( let l of lines ) {
      highlight(l);
    }
  }
});
