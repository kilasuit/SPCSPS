// Copyright ©2014 by Jeffrey Paarhuis
//----------------------------------------------------------------------------- 
// Filename : news.js 
//----------------------------------------------------------------------------- 
// Date of creation : 16-02-2014 
//----------------------------------------------------------------------------- 
// Contains the JavaScript code used for managing the news items 
//-----------------------------------------------------------------------------


$(document).ready(function() {

	getNews();
	
});//end (document).ready


function getNews()
{

	$().SPServices({
    	operation: "GetListItems",
        async: false,
        listName: "News",
		CAMLViewFields: "<ViewFields><FieldRef Name='Title' /><FieldRef Name='NewsSum' />\
		<FieldRef Name='NewsText' /><FieldRef Name='Modified' /><FieldRef Name='ID' /></ViewFields>",
		CAMLQuery: "<Query><OrderBy><FieldRef Name='Created' Ascending='False' /></OrderBy></Query>", 
			completefunc: function (xData, Status) {
			
	                var itemCount = parseFloat($(xData.responseXML).SPFilterNode("rs:data").attr("ItemCount"));
	                
	                if (itemCount != 0)
	                {
	                	$(xData.responseXML).SPFilterNode("z:row").each(function() {
	                	
		                	var title = $(this).attr('ows_Title');
		                	var newsSum = $(this).attr('ows_NewsSum');
		                	var newsText = $(this).attr('ows_NewsText');
		                	var newsID = $(this).attr('ows_ID');
	
		                	var SPDate = ($(this).attr('ows_Modified')).split(" ")[0];
							var dateParts = SPDate.split("-");
							var screenDate = new Date(dateParts[0], (dateParts[1] - 1) ,dateParts[2]);
							var dateString = screenDate.toLocaleDateString();
		                	
							var html = "<div class='newsitem'>\
                                            <h3>"+ title + "</h3>\
		                				    <span class='newsDate'>Last update: " + dateString + "</span>\
                                            <br/>\
		                				    <span>" + newsSum + "</span>\
                                            <br />\
                                            <a href='#' id='"+ newsID + "_btn'class='readMore'>Read more &raquo;</a>\
		                				    <div class='helpText' id='" + newsID + "' title='" + title + "'>" + newsText + "</div>\
                                        </div>";
		                	
		                	$('#newsItems').append(html);
		                	$('.helpText').hide();
		                	
		                	$("#"+newsID+"_btn").click(function()	{
		                	
		                	    $( "#dialog:ui-dialog" ).dialog( "destroy" );
			
							    $( "#" + newsID ).dialog({
								    width: 650,
								    modal: true,
								    buttons:{ "Sluiten": function() { $(this).dialog("close"); } },
								    height: "110%"
							    });
		
						    });//end info button

                	
				
						});//end each
	                	
	                }//end if
              
           		}//end completefunc
           		
    });//end SPServices
}