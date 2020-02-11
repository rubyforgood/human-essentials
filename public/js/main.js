$(document).ready(function(){
	
	/*  Foundation Init    */
	$(document).foundation();

	/*  carousel Init    */
	$('#carousel').carouFredSel({
	 	width : '670',
	 	pagination  : ".pagination",
	 	responsive : true,
	 	scroll :{
	 		fx : 'fade',
      duration: 1250,
      pauseOnHover: true
	 	},
	 	items :{
	 		visible : 1,
	 		width : '670'
	 	},
		swipe: {
			onMouse: true,
			onTouch: true
		}
    });

    /*    Mean navigation menu scroll to    */
    $('#mean_nav ul li a').click(function(e){
    	scrollTo($(this).attr('href'), 900, 'easeInOutCubic');
    });

    /*    Back to top button    */
    var back_top = $('#back_top');

    back_top.click(function(e){
    	e.preventDefault();
    	scrollTo(0, 900, 'easeInOutCubic');
    	
    });

    function scrollTo(target, speed, ease){
    	$(window).scrollTo(target, speed, {easing:ease});
    }

    $(window).on('scroll', function(){    
	    if($(this).scrollTop()>749)
	    {
	    	back_top.stop().animate({opacity : 1}, 250);
	    }else
	    {
	    	back_top.stop().animate({opacity : 0}, 250);	    
	    }   
    });

});
