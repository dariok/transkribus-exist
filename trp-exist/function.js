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
window.addEventListener('DOMContentLoaded', function (event) {
  const lines = document.getElementsByClassName("lineok");
  for ( let l of lines ) {
     highlight(l);
  }
});
