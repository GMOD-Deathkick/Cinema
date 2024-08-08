local SERVICE = {}

SERVICE.Name = "Dopebox"
SERVICE.IsTimed = true

SERVICE.Dependency = DEPENDENCY_COMPLETE

function SERVICE:Match( url )
	return url.host and url.host:match("dopebox.to")
end

local EMBED_URL = "https://rabbitstream.net/v2/embed-4/%s?_debug=true"

if (CLIENT) then
    --local test = "https://"
	local THEATER_JS = [[
        var player = jwplayer();

        // Ensure the player is set up before we start monitoring
        player.on('ready', function() {
            window.cinema_controller = player;
            exTheater.controllerReady();
            document.body.style.backgroundColor = "black";
            
            player.play(); // Auto-play when ready
        });

        // Monitor the player's state and sync with other clients
        setInterval(function() {
            var state = player.getState();
            if (state === "buffering") {
                player.play(); // Resume after buffering
            } else if (state === "paused") {
                player.play(); // Ensure playback stays active
            } else if (state === "error") {
                player.stop();
                player.play(); // Reload on error
            } else if ( state === "idle" ) {
                window.cinema_controller = player;
                exTheater.controllerReady();
                document.body.style.backgroundColor = "black";
                
                player.play(); // Auto-play when ready
                player.setCurrentCaptions(null);
            } else {
                
            }
        }, 100);

        function toggleCaptions() {
            var captionsList = player.getCaptionsList();
            if (captionsList.length > 0) {
                var currentCaptions = player.getCurrentCaptions();
                exTheater.print( currentCaptions );
                
                if (currentCaptions === null || currentCaptions === 0) {
                    // Enable English captions if none are currently enabled
                    var englishIndex = captionsList.findIndex(track => track.label === "English");
                    if (englishIndex !== -1) {
                        player.setCurrentCaptions(englishIndex);
                    }
                } else {
                    // Disable captions if they are currently enabled
                    player.setCurrentCaptions(null);
                }
            }
        }
    ]];

    local THEATER_INTERFACE = [[
		if (!window.theater) {
			class CinemaPlayer {

				get player() {
					return window.cinema_controller;
				}

				setVolume(volume) {
					if (!!this.player) {
						this.player.setVolume( volume );
					}
				}

				seek(second) {
					if (!!this.player && !!this.player.getCurrentTime()) {
						this.player.seek( second );
					}
				}

				sync(time) {
					if (!!this.player && !!this.player.getCurrentTime() && !!time) {

						var current = this.player.getCurrentTime();
						if ((current !== null) &&
							(Math.abs(time - current) > 7)) {
							this.player.seek( time+1 );
						}
					}
				}

			};
            window.dopebox = true;
			window.theater = new CinemaPlayer();
		}
	]]

	function SERVICE:LoadProvider( Video, panel )
        http.Fetch( "https://dopebox.to/ajax/movie/episodes/" .. Video:Data(), 
        function( body )
            --"://"
            local pattern = '<a data%-id="(%d+)"%s+id="watch%-%d+"%s+href="javascript:;"%s+class="btn btn%-block btn%-play link%-item">%s*<i class="fas fa%-play"></i>Server%s*<span>Vidcloud</span>%s*</a>'
            local deepdataID = string.match(body, pattern)
            if not deepdataID then return end
            http.Fetch("https://dopebox.to/ajax/get_link/" .. deepdataID, 
            function(body) 
                --"://"
                    local json = util.JSONToTable(body)
                    if json and json.link then
                        json.link = string.match(json.link, "/embed%-4/(.-)%?z=")
                        panel:OpenURL( EMBED_URL:format( json.link ) )
                        panel.OnDocumentReady = function(pnl)
                            self:LoadExFunctions( pnl, THEATER_INTERFACE )
                            pnl:QueueJavascript(THEATER_JS)
                        end
                    else
                        print("Failed to fetch embed URL")
                    end
                end, 
                function(err)
                    print("HTTP fetch failed1:", err)
                end
            )
            end,
            function(err)
                print("HTTP fetch failed2:", err)
            end
        )
		

	end
end

function SERVICE:GetURLInfo( url )

    local info = {}
    self.Original = "https://dopebox.to/" .. url.path
    --"://"

    local dataID = url.path:match("/movie/.-(%d+)")

    http.Fetch( self.Original, function( body )
        if not dataID then return end
        http.Fetch( "https://dopebox.to/ajax/movie/episodes/" .. dataID, 
        function( body )
            --"://"
            local pattern = '<a data%-id="(%d+)"%s+id="watch%-%d+"%s+href="javascript:;"%s+class="btn btn%-block btn%-play link%-item">%s*<i class="fas fa%-play"></i>Server%s*<span>Vidcloud</span>%s*</a>'
            local deepdataID = string.match(body, pattern)
            if not deepdataID then return end
            http.Fetch("https://dopebox.to/ajax/get_link/" .. deepdataID, 
            function(body) 
                --"://"
                    local json = util.JSONToTable(body)
                    if json and json.link then
                        json.link = string.match(json.link, "/embed%-4/(.-)%?z=")

                        info.Data = json.link
                        return { Data = json.link }
                    else
                        print("Failed to fetch embed URL")
                    end
                end, 
                function(err)
                    print("HTTP fetch failed1:", err)
                end
            )
            end,
            function(err)
                print("HTTP fetch failed2:", err)
            end
        )
        end,
        function( body )
        end    
        )
        
        
    if dataID then
        info.Data = dataID
    end

    return info.Data and info or false

end

function SERVICE:GetVideoInfo( data, onSuccess, onFailure )
	    local info = {}
        http.Fetch(self.Original, 
            function(body)
                local poster_url = string.match(body, '<img class="film%-poster%-img"%s+src="(.-)"')
                info.thumbnail = poster_url
                info.title = string.match(body, '<h2 class="heading%-name"><a%s+href="[^"]+">([^<]+)</a>')
                info.duration = tonumber( string.match(body, '<span%s+class="duration">[%s]*(%d+)%s*min</span>') ) * 60
                if onSuccess then
                    PrintTable( info )
                    pcall(onSuccess, info)
                end
            end, 
            function(err)
                print("HTTP fetch failed:", err)
            end
        )

        

end

theater.RegisterService( "dopebox", SERVICE )