module( "theater", package.seeall )

function AddAnnouncement( tbl )
	if not istable(tbl) then return end

	local key = table.remove(tbl, 1)
	local values = translations:FormatChat( key, unpack(tbl) )
	deathkick.ChatAddText( ColDefault, unpack(values) )
	print( "tried" )
end

net.Receive( "TheaterAnnouncement", function()
	AddAnnouncement( net.ReadTable() )
end )