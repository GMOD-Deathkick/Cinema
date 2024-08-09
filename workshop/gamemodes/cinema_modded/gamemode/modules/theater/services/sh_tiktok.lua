local SERVICE = {}

SERVICE.Name = "Dopebox"
SERVICE.IsTimed = true

SERVICE.Dependency = DEPENDENCY_COMPLETE

function SERVICE:Match( url )
	return url.host and url.host:match("tiktok.com")
end

local EMBED_URL = ""

if (CLIENT) then    
	local THEATER_JS = [[ 

        setInterval(function() { }, 100);

    ]]

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

    end
end

function SERVICE:GetURLInfo( url )

end

function SERVICE:GetVideoInfo( data, onSuccess, onFailure )

end

theater.RegisterService( "tiktok", SERVICE )