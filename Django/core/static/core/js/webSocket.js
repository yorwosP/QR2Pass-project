/*
    webSocket.js
    sets up websocket to the server and handles following commands: 
    - reload (to reload the page once authenticated)
    - logout (logout all user sessions - in every browser)
    - loading (notify user that out of band request has been received - 
        show animation that we are processing it)
    - redirect (to redirect to login page once registered)
    - stop (if the loading needs to be cancelled for any reason) - incomplete 

*/

wsProtocol = window.location.protocol == 'https:' ? 'wss://' : 'ws://'
const wSocket = new WebSocket(
    wsProtocol +
    window.location.host +
    '/ws/'

);

wSocket.onmessage = function (e) {
    const data = JSON.parse(e.data);
    if (data.command) {
        // console.log(`${Date.now()}:received command`);
        const origin = window.location.origin;

        if (data.command == 'reload') {
            //user logged in go to page defined by the next parameter
            // or to login page (server will redirect us to the proper page)
            const queryString = window.location.search;
            const urlParams = new URLSearchParams(queryString);
            const next = urlParams.get('next');
            var gotoUrl = origin;
            if (next) {
                gotoUrl += next;
            } else {
                gotoUrl += '/core/login';
            }


            setTimeout(() => {
                window.location.href = gotoUrl;
            }, 2000);


        } else if (data.command == 'logout') {
            // user logged out in some other session (browser window)
            // logout this session as well.
            var gotoUrl = origin + '/core/logout';
            console.log(gotoUrl);
            console.log('going to log out');
            setTimeout(() => {
                window.location.href = gotoUrl;
            }, 2000);

        } else if (data.command == 'redirect') {
            // user finished registration
            // redirect them to login page
            // TODO: maybe redirect them to first page instead? 
            var gotoUrl = origin + '/core/login';
            console.log(`${Date.now()}: going to redirect to login`);
            console.log(gotoUrl);
            // stopLoading();
            setTimeout(() => {
                window.location.href = gotoUrl;
            }, 10000); // !!CHECK!! 10000? is this correct? 

        } else if (data.command == 'loading') {
            // user scanned image (via the app)
            // notify them that the request is being processed
            // console.log(`${Date.now()}: will call startLoading`);
            startLoading();

        } else if (data.command == 'stop') {
            // server wants to cancel this procedure for some reason
            // stop the loading animations
            // console.log("stop loading");
            stopLoading();

        }

    } else if (data.message) {
        // received message instead of command
        // nothing to do
        console.log(message)
    }

};

wSocket.onclose = function (e) {
    console.error('Chat socket closed unexpectedly');
};



function startLoading() {
    // animation to show that the server is processing
    // a request received out of band (i.e via the app)
    // hide the countdown stuff
    $("#countdown").addClass("hidden");
    $("svg").css("display", "none")
    $("svg").addClass("hidden");
    // set the message in a overlay
    $(".overlay p").html('Request reveived. Processing');
    // show the overlay
    $(".overlay").addClass("visible");
    // add an animated spinner 
    $(".spinner").addClass("visible");



};


function stopLoading() {
    // !!TODO!! : this is incomplete
    $(".overlay").css("display", "none");

};