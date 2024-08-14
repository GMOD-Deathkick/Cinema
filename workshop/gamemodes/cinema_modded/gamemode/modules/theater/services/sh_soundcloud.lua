local SERVICE = {}

SERVICE.Name = "Soundcloud"
SERVICE.IsTimed = true

SERVICE.Dependency = DEPENDENCY_COMPLETE
SERVICE.ExtentedVideoInfo = true

function SERVICE:Match( url )
	return url.host and url.host:match("soundcloud.com")
end

local API_URL = "https://soundcloud.com/oembed?format=json&url=%s"
    -- "://"

if (CLIENT) then 
    local EMBED_HTML = [[
        <!doctype html>
        <html>
        <head>
        <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
        <script src="http://w.soundcloud.com/player/api.js"></script>
        <script>
        var widget
        $(document).ready(function() {
            var widget = SC.Widget(document.getElementById('soundcloud_widget'));
            widget.bind(SC.Widget.Events.READY, function() {
                window.cinema_controller = widget;
                exTheater.controllerReady();
                widget.play();
            }); 
        });
        </script>
        </head>
        <body>
        <iframe id="soundcloud_widget"
            src="%IFRAME_URL%"
            width="100%"
            height="100%"
            allow="autoplay; fullscreen"
            frameborder="no"></iframe>
        </body>
        </html>
    ]]
    -- "://"

    local THEATER_INTERFACE = [[
		if (!window.theater) {
			class CinemaPlayer {

				get player() {
					return window.cinema_controller;
				}

				setVolume(volume) {
                    var widget = SC.Widget(document.getElementById('soundcloud_widget'));
					if (!!widget) {
						widget.setVolume( volume );
                        exTheater.print( "volume" + volume );
					}
				}

				seek(second) {
                    var widget = SC.Widget(document.getElementById('soundcloud_widget'));
                    widget.getDuration(function( curtime ) {
                        if (!!widget && !!curtime) {
                            widget.seekTo( second*1000 );
                        }
                    });
				}

				sync(time) {
                    var widget = SC.Widget(document.getElementById('soundcloud_widget'));
                    widget.getDuration(function( curtime ) {
                        if (!!widget && !!curtime && !!time) {

                            var current = curtime/1000;
                            if ((current !== null) &&
                                (Math.abs(time - current) > 3)) {
                                    exTheater.print( time + current );
                                widget.seekTo( time*1000 ); 
                            }
                        }
                    });
				}

			};
            
			window.theater = new CinemaPlayer();
		}
	]]

    local META_JS = [[
        setInterval(function() { 
            var widget = SC.Widget(document.getElementById('soundcloud_widget'));
            
            widget.getDuration(function(duration) {
                if ( duration && duration > 0 ) {
                    console.log("CINEMA: " + duration );
                }
              });
                       
        }, 100);
    ]]

    function SERVICE:LoadProvider( Video, panel )
        http.Fetch( API_URL:format( Video:Data() ),
        function( body )
            local json = util.JSONToTable( body )
            if json then
                panel:SetHTML( string.Replace( EMBED_HTML, "%IFRAME_URL%", json.html:match('src="(.-)"') ) )
                panel.OnDocumentReady = function(pnl)
                    SERVICE:LoadExFunctions( pnl, THEATER_INTERFACE )
                end
            end
        end )


    end

    function SERVICE:GetMetadata( data, callback )        
		local panel = vgui.Create("DHTML")
		panel:SetMouseInputEnabled(false)
        print( data, "sethtml" )
        panel:SetHTML( string.Replace( EMBED_HTML, "%IFRAME_URL%", data ) )
        panel.OnDocumentReady = function(pnl)
            pnl:QueueJavascript(META_JS)
        end
        function panel:ConsoleMessage( msg )
            
            if not string.StartsWith( msg, "CINEMA: " ) then print( msg ) return end
            print( msg )
            local seconds = string.sub( msg, 9, string.len( msg ) )
            callback( { duration = seconds } )
            panel:Remove()
            
        end
    end

end

function SERVICE:GetURLInfo( url )
    local path = "https://" .. url.host .. url.path
    --"://"
    if not url.path:match("/[^/]+/[^/]+$") then return false end 
    
    return { Data = path }    
    
end

    -- "://"
function SERVICE:GetVideoInfo( data, onSuccess, onFailure )
    http.Fetch( API_URL:format( data:Data() ),
        function( body )
            local json = util.JSONToTable( body )
            if json then
                local info = {
                    title = json.author_name .. " - " .. json.title,
                    thumbnail = json.thumbnail_url,
                }
                data._VideoData = json.html:match('src="(.-)"')
                theater.FetchVideoMedata( data:GetOwner(), data, 
                function(metadata)
                    if not metadata.duration or not isnumber( tonumber( metadata.duration ) ) then pcall( onFailure, "Metadata Not Found" ) end 
                    info.duration = tonumber( metadata.duration/1000 )
                    if onSuccess then
                        pcall(onSuccess, info)
                    end
                end )
                

                
            else
                if onFailure then
                    pcall( onFailure, "Data Not Found!")
                end
            end
        end )   

end

theater.RegisterService( "soundcloud", SERVICE )