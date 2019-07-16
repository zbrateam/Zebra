/*!
 * Start Bootstrap - New Age v5.0.6 (https://startbootstrap.com/template-overviews/new-age)
 * Copyright 2013-2019 Start Bootstrap
 * Licensed under MIT (https://github.com/BlackrockDigital/startbootstrap-new-age/blob/master/LICENSE)
 */

!function(e){"use strict";e('a.js-scroll-trigger[href*="#"]:not([href="#"])').click(function(){if(location.pathname.replace(/^\//,"")==this.pathname.replace(/^\//,"")&&location.hostname==this.hostname){var a=e(this.hash);if((a=a.length?a:e("[name="+this.hash.slice(1)+"]")).length)return e("html, body").animate({scrollTop:a.offset().top-48},1e3,"easeInOutExpo"),!1}}),e(".js-scroll-trigger").click(function(){e(".navbar-collapse").collapse("hide")}),e("body").scrollspy({target:"#mainNav",offset:54});function a(){100<e("#mainNav").offset().top?e("#mainNav").addClass("navbar-shrink"):e("#mainNav").removeClass("navbar-shrink")}a(),e(window).scroll(a)}(jQuery);