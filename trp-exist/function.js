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
        document.getElementById('collection-info').innerHTML = '<a href="?sessionId=' + searchParams.get('sessionId') + '">List collections</a>';
      }
    }
    req.onloadstart = () => { document.getElementById('collection-info').innerHTML = "loading"; }
    req.onprogress = () => { document.getElementById('collection-info').innerHTML += "."; }
    req.open('GET', listsUrl);
    req.send();
  } else if ( window.location.pathname.endsWith("compare.html") ) {
    const collection = searchParams.get('collection')
        , documentId = searchParams.get('document')
        , sessionId = searchParams.get('sessionId')
        , page = searchParams.has('page') ? parseInt(searchParams.get('page')) : 1;
    
    let url = `/exist/restxq/trpex/collections/${collection}/${documentId}/info`
      , mdUrl = new URL(url, window.location.href)
      , mdReq = new XMLHttpRequest()
      , pageNav = document.createElement('p');

    mdReq.onload = () => {
      if ( mdReq.status == 200 ) {
        let mdResponse = JSON.parse(mdReq.response)
          , numPages = mdResponse.md.nrOfPages;
        document.getElementById('comparison-info').outerHTML
           = `<div>
                <h1>${mdResponse.md.title} ( ${mdResponse.collection.colName} )</h1>
                <p><a href="collections.html?sessionId=${sessionId}&collection=${collection}">back to document list</a></p>
              </div>`;
        
        pageNav.innerHTML = `<a href="?sessionId=${sessionId}&document=${documentId}&collection=${collection}&page=1">1</a> `
        if ( page > 2) pageNav.innerHTML
            += `&lt;&lt; <a href="?sessionId=${sessionId}&document=${documentId}&collection=${collection}&page=${page - 1}">${page - 1}</a> `;
        pageNav.innerHTML += `[${page} of ${numPages}]`;
        if ( page < numPages ) pageNav.innerHTML
            += ` <a href="?sessionId=${sessionId}&document=${documentId}&collection=${collection}&page=${page + 1}">${page + 1}</a>`;
        pageNav.innerHTML += ` &gt;&gt; <a href="?sessionId=${sessionId}&document=${documentId}&collection=${collection}&page=${numPages}">${numPages}</a>`;
      } else {
        console.log(req.response);
      }
    }
    mdReq.open("GET", mdUrl);
    mdReq.send();

    url = `/exist/restxq/trpex/compare/${collection}/${documentId}/${page}/latest`;
    
    let compareUrl = new URL(url, window.location.href);
    compareUrl.searchParams.set("sessionId", searchParams.get('sessionId'));

    let req = new XMLHttpRequest();
    req.onload = () => {
      if ( req.status != 200 ) {
        console.log("error: ", req.response);
        document.getElementById('comparison-info').innerHTML = "Error getting info";
      } else {
        const parser = new DOMParser()
            , comparison = parser.parseFromString(req.responseText,'text/html');
        
        document.getElementById('comparison')?.appendChild(comparison.getElementsByTagName('style')[0]);
        document.getElementById('comparison')?.appendChild(comparison.getElementsByTagName('h2')[0]);
        document.getElementById('comparison')?.appendChild(pageNav);
        document.getElementById('comparison')?.appendChild(comparison.getElementsByTagName('table')[0]);
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
