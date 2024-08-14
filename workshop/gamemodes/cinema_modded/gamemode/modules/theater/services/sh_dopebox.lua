local SERVICE = {}

SERVICE.Name = "Dopebox"
SERVICE.IsTimed = true

SERVICE.Dependency = DEPENDENCY_COMPLETE

function SERVICE:Match( url )
	return url.host and url.host:match("dopebox.to")
end

local EMBED_URL = "https://rabbitstream.net/v2/embed-4/%s?_debug=true"
    --"://"

    local function extractDataIds(html)
        local vidcloud = {}
        local pattern = '<a data%-id="(%d+)"%s+id="watch%-%d+"%s+href="javascript:;"%s+class="btn btn%-block btn%-play link%-item">%s*<i class="fas fa%-play"></i>Server%s*<span>([^<]+)</span>%s*</a>'
    
        for data_id, server in html:gmatch(pattern) do
            table.insert(vidcloud, {id = data_id, server = server})
        end
    
        local services = { Vidcloud = "", UpCloud = "" }
        local vidtest = table.Copy( vidcloud )
        for id, server in pairs( vidtest ) do
            if services[ server.server ] then continue end
            vidcloud[ id ] = nil
        end
        return vidcloud
    end

if (CLIENT) then
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
            
			window.theater = new CinemaPlayer();
		}
	]]

    local function ParseURLFromID( data, type, panel )
        local types = {
            Movie = "https://dopebox.to/ajax/movie/episodes/",
            TV = "https://dopebox.to/ajax/episode/servers/"
        }
        http.Fetch( data, 
        function(body)
            local info = ""
            if type == "TV" then
            local pattern = 'data%-episode="(%d+)"'
            local episode_id = string.match(body, pattern)
                info = types.TV .. episode_id
            elseif type == "Movie" then
                info = types.Movie .. data:match("/movie/.-(%d+)")
            end
            
            http.Fetch( info,
            function( body )
                local ids = extractDataIds( body )
                if not ids then return end
                local deepdataID = table.Random( ids ).id
                
                if not deepdataID then return end
                http.Fetch("https://dopebox.to/ajax/get_link/" .. deepdataID, 
                function(body) 
                    --"://"
                    local json = util.JSONToTable(body)
                    if json and json.link then
                        json.link = string.match(json.link, "/embed%-4/(.-)%?z=")
                        panel:OpenURL( EMBED_URL:format( json.link ) )
                        panel.OnDocumentReady = function(pnl)
                            SERVICE:LoadExFunctions( pnl, THEATER_INTERFACE )
                            pnl:QueueJavascript(THEATER_JS)
                        end
                    else
                        print("Failed to fetch embed URL")
                    end
                end )
            end )
        end )
    end

	function SERVICE:LoadProvider( Video, panel )
        local tempid = Video:Data():match("/movie/.-(%d+)")
        if not tempid then 
            local show, episode = string.match(Video:Data(), "%-(%d+)%.(%d+)$")

            if show and episode then
                ParseURLFromID( Video:Data(), "TV", panel )
            end
        else
            ParseURLFromID( Video:Data(), "Movie", panel )
        end
    end
end 


function SERVICE:GetURLInfo( url )
    local info = {}
    self.Original = "https://dopebox.to" .. url.path
    --"://"

    local dataID = url.path:match("/movie/.-(%d+)")
    if not dataID then 
        dataID = self.Original
        local show, episode = string.match(url.path, "%-(%d+)%.(%d+)$")

        if show and episode then
            return { Data = self.Original }
        else 
            return false 
        end
    else
        return { Data = self.Original }
    end

    if dataID then
        info.Data = dataID
    end

    return info.Data and info or false
end

function SERVICE:GetVideoInfo( data, onSuccess, onFailure )
	    local info = {}
        
        http.Fetch(self.Original, 
            function(body)
                local dataID = self.Original:match("/movie/.-(%d+)")
                if not dataID then 
                    dataID = self.Original
                    local show, episode = string.match(self.Original, "%-(%d+)%.(%d+)$")

                    if show and episode then
                        local poster_url = string.match(body, '<img class="film%-poster%-img"%s+src="(.-)"')
                        info.thumbnail = poster_url
                        local season, episode, episodeName = body:match('Season (%d+) Episode (%d+):%s*(.+)')
                        if not season then season = "" end
                        if not episode then episode = "" end
                        if not episodeName then episodeName = "" end
                        info.title = string.match(body, '<h2 class="heading%-name"><a%s+href="[^"]+">([^<]+)</a>') .. " S" ..season.. "E" .. episode, ": " .. episodeName
                        local dur = 240
                        if body:match('class="duration">(%d+)') ~= "N/A" then dur = body:match('class="duration">(%d+)') end

                        info.duration = tonumber( dur) * 60
                        if onSuccess then
                            pcall(onSuccess, info)
                        end
                    end
                else
                    local poster_url = string.match(body, '<img class="film%-poster%-img"%s+src="(.-)"')
                        info.thumbnail = poster_url
                        info.title = string.match(body, '<h2 class="heading%-name"><a%s+href="[^"]+">([^<]+)</a>')
                        local dur = 240
                        if body:match('class="duration">(%d+)') ~= "N/A" then dur = body:match('class="duration">(%d+)') end
                        info.duration = tonumber( dur ) * 60
                        if onSuccess then
                            pcall(onSuccess, info)
                        end
                end

                        
            end, 
            function(err)
                print("HTTP fetch failed:", err)
            end
        )

        

end

theater.RegisterService( "dopebox", SERVICE )