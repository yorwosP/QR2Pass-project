/*
    countdown.js
    provide a countdown timer (and animating circle)
    this is linked to circle svg (with radius 30px)
*/


function seconds_since_epoch() {

    var currentDate = new Date();
    return Math.floor(currentDate / 1000);
}


$(document).ready(function () {
    var countdown = 60; // in seconds
    var initDate = seconds_since_epoch();

    $("svg circle").animate({
        // animate the stroke-dashoffset from 0 to 
        // circumference of the circle (2*pi*r) 
        'stroke-dashoffset': 188



    }, countdown * 1000, 'linear', function () {
        // Animation complete.
    });


    var countdownNumberElement = $("#countdown-number");
    // var startedBlurTime = null;

    $(window).on('focus', function () {
        // timer is paused when losing focus from the tab/window
        // need to recalculate elapsed time when focus is gained again 
        td = seconds_since_epoch() - initDate;
        countdown = td < 60 ? 60 - td : 0;

    });




    $("#countdown-number").text(countdown);
    timer = setInterval(function () {
        // recalibrate countdown if more than 60 seconds passed while away (unfocused) 
        // (i.e don't let go under 0)
        countdown = --countdown <= 0 ? 0 : countdown;

        countdownNumberElement.text(countdown);
        if (countdown <= 12) {
            // hack to make the stroke of the circle red when animation almost finished
            $("svg circle").css("stroke", "red");

        }
        if (countdown <= 0) {
            // timer finished
            // 1. stop the timer 
            clearInterval(timer);
            // 2. execute finished animation
            $("svg circle").addClass("stopped");
            // 3. hide the countdown and all SVGs
            timeout = setTimeout(() => {

                $("#countdown").addClass("hidden");
                $("svg").css("display", "none")
                $("svg").addClass("hidden");
                // 4. show overlay
                $(".overlay").addClass("visible")

            }, 600);

        }
    }, 1000);




});