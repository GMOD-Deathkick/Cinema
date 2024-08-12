local b = ""
--[[

    function getTikTokVideoId(url) {
        let regex = /tiktok\.com\/.*\/video\/(\d+)(?:\?|$)/;
        let match = url.match(regex);
        return match ? match[1] : null;
    }

    // Function to get the TikTok embed code using oEmbed API
    function getTikTokEmbedData(url) {
        return fetch(`https://www.tiktok.com/oembed?url=${encodeURIComponent(url)}`)
            .then(response => response.json());
    }

    // Function to create the TikTok embed and autoplay the video
    function createTikTokEmbed(videoId, title) {
        // Clear the body
        document.body.innerHTML = '';

        // Create header for title
        let header = document.createElement('div');
        header.style.position = 'fixed';
        header.style.top = '0';
        header.style.left = '0';
        header.style.width = '100vw';
        header.style.padding = '10px';
        header.style.backgroundColor = 'rgba(0, 0, 0, 0.5)';
        header.style.color = 'white';
        header.style.fontSize = '18px';
        header.style.zIndex = '1001';
        header.innerText = title;
        document.body.appendChild(header);

        // Create the current time and duration display
        let timeDisplay = document.createElement('div');
        timeDisplay.style.position = 'fixed';
        timeDisplay.style.top = '0';
        timeDisplay.style.right = '10px';
        timeDisplay.style.padding = '10px';
        timeDisplay.style.backgroundColor = 'rgba(0, 0, 0, 0.5)';
        timeDisplay.style.color = 'white';
        timeDisplay.style.fontSize = '18px';
        timeDisplay.style.zIndex = '1002';
        timeDisplay.innerText = '0:00 / 0:00';
        document.body.appendChild(timeDisplay);

        // Create the TikTok embed iframe
        let iframe = document.createElement('iframe');
        iframe.src = `https://www.tiktok.com/player/v1/${videoId}?controls=0&autoplay=1&fullscreen_button=0&play_button=0&volume_control=0&timestamp=0&loop=1&description=0&music_info=0&rel=0`;
        iframe.style.position = 'fixed';
        iframe.style.top = '0';
        iframe.style.left = '0';
        iframe.style.width = '100vw';
        iframe.style.height = '100vh';
        iframe.style.zIndex = '999';
        iframe.style.border = 'none';
        iframe.allow = 'autoplay; fullscreen';
        document.body.appendChild(iframe);

        // Function to update the current time and duration
        function updateTimeDisplay(currentTime, duration) {
            let currentMinutes = Math.floor(currentTime / 60);
            let currentSeconds = Math.floor(currentTime % 60);
            let durationMinutes = Math.floor(duration / 60);
            let durationSeconds = Math.floor(duration % 60);
            timeDisplay.innerText = `${currentMinutes}:${currentSeconds.toString().padStart(2, '0')} / ${durationMinutes}:${durationSeconds.toString().padStart(2, '0')}`;
        }

        // Listen for messages from the iframe to update the current time and duration
        window.addEventListener('message', (event) => {
            if (event.data && event.data['x-tiktok-player']) {
                switch (event.data.type) {
                    case 'onCurrentTime':
                        updateTimeDisplay(event.data.value.currentTime, event.data.value.duration);
                        break;
                }
            }
        });
    }

    // Add an event listener to the button
    button.addEventListener('click', function() {
        let url = inputBox.value;
        let videoId = getTikTokVideoId(url);
        if (videoId) {
            getTikTokEmbedData(url).then(data => {
                createTikTokEmbed(videoId, data.title);
            }).catch(() => alert('Invalid TikTok URL or video unavailable'));
        } else {
            alert('Invalid TikTok URL');
        }
    });
})();

]]

local SERVICE = {}

SERVICE.Name = "Tiktok"
SERVICE.IsTimed = true

SERVICE.Dependency = DEPENDENCY_COMPLETE

function SERVICE:Match( url )
	return url.host and url.host:match("www.tiktok.com")
end

local EMBED_URL = ""

if (CLIENT) then    
	local THEATER_JS = [[ 

        setInterval(function() { }, 100);

    ]]

    function SERVICE:LoadProvider( Video, panel )
        print( "this ran 2" )
    end
end

function SERVICE:GetURLInfo( url )
    local info = {}
    if url.path then
		local data = url.path:match("/@[%w%.]+/video/(%d+)$")
        print( data )
		if data and data ~= nil then return { Data = data } end
	end

    return false  
end

function SERVICE:GetVideoInfo( data, onSuccess, onFailure )
    print( "this ran part 3" )
    return false
end