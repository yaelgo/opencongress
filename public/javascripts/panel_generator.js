function onSearch() {
  Element.show('search_spinner'); // spinner
}

function onSearchComplete() {
  Element.hide('search_spinner');
}

function setBillStatusBillId(billId) {
  document.getElementById('panel_bill_id').value = billId;
  updateBillStatusFields(); 
}

function setIssueBillsIssueId(issueId) {
  document.getElementById('panel_issue_id').value = issueId;
  updateIssueBillsFields(); 
}

function updateSyndicatorFields(changedField) {
  updateFields(changedField, "syndicator");
}

function updateBillStatusFields(changedField) {  
  updateFields(changedField, "bill_status");
}

function updateIssueBillsFields(changedField) {  
  updateFields(changedField, "issue_bills");
}

function updateMypnFields(changedField) {  
  updateFields(changedField, "mypn");
}

var passBills = '';
var dontPassBills = '';
function updateWatchingFields(changedField) {  
  updateFields(changedField, "watching");
}

function addWatchingBillId(billId, pass) {
  if (pass) {
    if (passBills == '')
      passBills += billId;
    else 
      passBills += "," + billId;
  } else {
    if (dontPassBills == '')
      dontPassBills += billId;
    else 
      dontPassBills += "," + billId;
  }

  updateFields(null, "watching")
}

function clearWatching() {
  passBills = ''
  dontPassBills = ''
  
  updateFields(null, "watching")
}

function generatorRefresh()
{
  updateFields(null, "bill_status", true);
}

function updateFields(changedField, panelType, generatorRefresh) {
  var previewQuery;
  var theIFrame;
  var frameHeight;
  var baseCode;
  
  if (panelType == 'bill_status')
  {
    baseCode = "<script type=\"text/javascript\">\n" +
                 "oc_host_url = \"#HOSTNAME\";\n" +
                 "oc_bill_id = \"#BILL_ID\";\n" +
                 "oc_frame_height = \"#FRAME_HEIGHT\";\n" +
                 "oc_bgcolor = \"#BGCOLOR\";\n" + 
                 "oc_textcolor = \"#TEXTCOLOR\";\n" + 
                 "oc_bordercolor = \"#BORDERCOLOR\";\n" + 
                 "</script>\n" + 
                 "<script type=\"text/javascript\" " +
                 "src=\"#HOSTNAMEjavascripts/bill_status.js\">\n</script>";  
  }
  else if (panelType == 'issue_bills') {
    baseCode = "<script type=\"text/javascript\">\n" +
                 "oc_host_url = \"#HOSTNAME\";\n" +
                 "oc_issue_id = \"#ISSUE_ID\";\n" +
                 "oc_item_type = \"#ITEMTYPE\";\n" + 
                 "oc_bgcolor = \"#BGCOLOR\";\n" + 
                 "oc_textcolor = \"#TEXTCOLOR\";\n" + 
                 "oc_bordercolor = \"#BORDERCOLOR\";\n" + 
                 "</script>\n" + 
                 "<script type=\"text/javascript\" " +
                 "src=\"#HOSTNAMEjavascripts/issue_bills.js\">\n</script>";      
  }
  else if (panelType == 'watching')
  {
    baseCode = "<script type=\"text/javascript\">\n" +
                 "oc_host_url = \"#HOSTNAME\";\n" +
                 "oc_pass_bills = \"#PASSBILLS\";\n" +
                 "oc_dont_pass_bills = \"#DONTPASSBILLS\";\n" +
                 "oc_bgcolor = \"#BGCOLOR\";\n" + 
                 "oc_textcolor = \"#TEXTCOLOR\";\n" + 
                 "oc_bordercolor = \"#BORDERCOLOR\";\n" + 
                 "</script>\n" + 
                 "<script type=\"text/javascript\" " +
                 "src=\"#HOSTNAMEjavascripts/watching.js\">\n</script>";
  }
  else if (panelType == 'mypn')
  {
    baseCode = "<script type=\"text/javascript\">\n" +
                 "oc_mypn_host_url = \"#HOSTNAME\";\n" +
                 "oc_mypn_user = \"#USER\";\n" +
                 "oc_mypn_num_items = \"#NUM_ITEMS\";\n" +
                 "oc_mypn_bgcolor = \"#BGCOLOR\";\n" + 
                 "oc_mypn_textcolor = \"#TEXTCOLOR\";\n" + 
                 "oc_mypn_bordercolor = \"#BORDERCOLOR\";\n" + 
                 "</script>\n" + 
                 "<script type=\"text/javascript\" " +
                 "src=\"#HOSTNAMEjavascripts/mypn_widget.js\">\n</script>";
  }
  else
  {
    baseCode = "<script type=\"text/javascript\">\n" +
                 "oc_host_url = \"#HOSTNAME\";\n" +
                 "oc_num_items = \"#NUM_ITEMS\";\n" +
                 "oc_item_type = \"#ITEMTYPE\";\n" + 
                 "oc_bgcolor = \"#BGCOLOR\";\n" + 
                 "oc_textcolor = \"#TEXTCOLOR\";\n" + 
                 "oc_bordercolor = \"#BORDERCOLOR\";\n" + 
                 "</script>\n" + 
                 "<script type=\"text/javascript\" " +
                 "src=\"#HOSTNAMEjavascripts/syndicator.js\">\n</script>";
  }

  if (changedField != null) {
    document.getElementById(changedField).value = document.getElementById(changedField + "_select").value    
  }

  var hostname = document.getElementById('panel_hostname').value;

  var bg_color = document.getElementById('panel_bgcolor').value ?
                 document.getElementById('panel_bgcolor').value : 'ffffff';
  var textcolor = document.getElementById('panel_textcolor').value ?
                  document.getElementById('panel_textcolor').value : '333333';
  var bordercolor = document.getElementById('panel_bordercolor').value ?
                    document.getElementById('panel_bordercolor').value : '999999';

  if (panelType == 'syndicator')
  {
    var num_items = document.getElementById('panel_number').value ?
                    document.getElementById('panel_number').value : '3';
    var item_type = document.getElementById('panel_item_type').value ?
                    document.getElementById('panel_item_type').value : 'viewed-bill';
    frameHeight = (document.getElementById('panel_number').value * 53) + 92;
  }
  else if (panelType == 'mypn') {
    var num_items = document.getElementById('panel_number').value ?
                    document.getElementById('panel_number').value : '3';
    var user = document.getElementById('panel_user').value
    frameHeight = (document.getElementById('panel_number').value * 53) + 92;
  }
  else if (panelType == 'issue_bills') {
    var issue_id = document.getElementById('panel_issue_id').value ?
                   document.getElementById('panel_issue_id').value : '4166';
    var item_type = document.getElementById('panel_item_type').value ?
                    document.getElementById('panel_item_type').value : 'new-bill';
    frameHeight = 338;
  }
  else if (panelType == 'bill_status')
  {
    var bill_id = document.getElementById('panel_bill_id').value ?
                  document.getElementById('panel_bill_id').value : '111-h1';
  } else if (panelType == 'watching') {
    num_pass_bills = (passBills == '' ? 0 : passBills.split(",").length);
    num_dont_pass_bills = (dontPassBills == '' ? 0 : dontPassBills.split(",").length);
    
    frameHeight = 52;
    frameHeight += (num_pass_bills + num_dont_pass_bills) * 53;
    if (num_pass_bills > 0) {
      frameHeight += 18;
    }
    if (num_dont_pass_bills > 0) {
      frameHeight += 18;
    }
  }   
    
                    
  previewQuery = "bg_color=" + bg_color +
                 "&textcolor=" + textcolor;
                 
  if (panelType == 'syndicator')
  {       
    previewQuery += "&item_type=" + item_type +
                    "&num_items=" + num_items;
  } else if (panelType == 'mypn') {
    previewQuery += "&num_items=" + num_items +
                    "&user=" + user;
  } else if (panelType == 'issue_bills') {
    previewQuery += "&item_type=" + item_type +
                    "&issue_id=" + issue_id;    
  } else if (panelType == 'watching') {
    previewQuery += "&pass_bills=" + passBills +
                    "&dont_pass_bills=" + dontPassBills;    
  }
  else {
    previewQuery += "&bill_id=" + bill_id;
  }
                
  theIFrame = document.getElementById(panelType + '_panel');

  oldUrl = theIFrame.src;
  theIFrame.src = document.getElementById('panel_path').value + "?" + previewQuery;
  

  if (panelType == 'bill_status')
  { 
    if (!generatorRefresh)
    {
      //if (theIFrame.addEventListener){
      //  theIFrame.addEventListener( "load", generatorRefresh, false); 
      //} else if (theIFrame.attachEvent){
      //  theIFrame.attachEvent( "onload", generatorRefresh);
      //}
      theIFrame.onLoad = setTimeout("parent.updateFields(null, 'bill_status', true)", 2000);
    }
    
    if (theIFrame.contentDocument && theIFrame.contentDocument.body.offsetHeight) //ns6 syntax
    {
      frameHeight = theIFrame.contentDocument.body.offsetHeight + 5; 
    }
    else if (theIFrame.Document && theIFrame.Document.body.scrollHeight) //ie5+ syntax
    {
      frameHeight = theIFrame.Document.body.scrollHeight;
    }
  }
  
  if (window.navigator.userAgent.indexOf("MSIE")) {
    theIFrame.height = frameHeight + 7;    
  } else {
    theIFrame.height = frameHeight;
  }
  theIFrame.style.borderColor = "#" + bordercolor;

  userCode = baseCode;
  userCode = userCode.replace(/#HOSTNAME/g, hostname);
  if (panelType == 'syndicator')
  {
    userCode = userCode.replace(/#ITEMTYPE/, item_type);
    userCode = userCode.replace(/#NUM_ITEMS/, num_items);
  } else if (panelType == 'mypn') {
    userCode = userCode.replace(/#NUM_ITEMS/, num_items);
    userCode = userCode.replace(/#USER/, user);
  } else if (panelType == 'issue_bills') {
    userCode = userCode.replace(/#ITEMTYPE/, item_type);
    userCode = userCode.replace(/#ISSUE_ID/, issue_id);    
  } else if (panelType == 'watching') {
    userCode = userCode.replace(/#PASSBILLS/, passBills);
    userCode = userCode.replace(/#DONTPASSBILLS/, dontPassBills);
  } else {
    userCode = userCode.replace(/#BILL_ID/, bill_id);
    userCode = userCode.replace(/#FRAME_HEIGHT/, frameHeight);
  }
  userCode = userCode.replace(/#BGCOLOR/, bg_color);
  userCode = userCode.replace(/#TEXTCOLOR/, textcolor);
  userCode = userCode.replace(/#BORDERCOLOR/, bordercolor);
   
  document.getElementById('panel_code').value = userCode;
}


