require 'rubygems'
require 'gosu'

TOP_COLOR = Gosu::Color.new(0xFF1EB1FA)
BOTTOM_COLOR = Gosu::Color.new(0xFF1D4DB5)
SCREEN_W = 800
SCREEN_H = 600
X_LOCATION = 500		# x-location to display track's name

module ZOrder
  BACKGROUND, PLAYER, UI = *0..2
end

module Genre
  POP, CLASSIC, JAZZ, ROCK = *1..4
end

GENRE_NAMES = ['Null', 'Pop', 'Classic', 'Jazz', 'Rock']

class ArtWork
	attr_accessor :bmp, :dim
	def initialize(file, leftX, topY)
		@bmp = Gosu::Image.new(file)
		@dim = Dimension.new(leftX, topY, leftX + @bmp.width(), topY + @bmp.height())
	end
end

class Album
	attr_accessor :title, :year, :artist, :artwork, :tracks
	def initialize (title, year, artist, artwork, tracks)
		@title = title
		@year = year
		@artist = artist
		@artwork = artwork
		@tracks = tracks
	end
end

class Track
	attr_accessor :name, :location, :dim
	def initialize(name, location, dim)
		@name = name
		@location = location
		@dim = dim
	end
end

class Dimension
	attr_accessor :leftX, :topY, :rightX, :bottomY
	def initialize(leftX, topY, rightX, bottomY)
		@leftX = leftX
		@topY = topY
		@rightX = rightX
		@bottomY = bottomY
	end
end


class MusicPlayerMain < Gosu::Window

	def initialize
	    super SCREEN_W, SCREEN_H
	    self.caption = "Music Player"
	    @track_font = Gosu::Font.new(25)
	    @albums = read_albums()
	    @album_playing = -1
	    @track_playing = -1
			@scene = :start
			@sort_queues = [:ascending_year,:descending_year,:artist]
			@sort_choice = 0
	end

  	# Read a single track
	def read_track(a_file, idx)
		track_name = a_file.gets.chomp
		track_location = a_file.gets.chomp
		# --- Dimension of the track's title ---
		leftX = X_LOCATION
		topY = 50 * idx + 30
		rightX = leftX + @track_font.text_width(track_name)
		bottomY = topY + @track_font.height()
		dim = Dimension.new(leftX, topY, rightX, bottomY)
		# --- Create a track object ---
		track = Track.new(track_name, track_location, dim)
		return track
	end

	# Read all tracks of an album
	def read_tracks(a_file)
		count = a_file.gets.chomp.to_i
		tracks = Array.new()
		# --- Read each track and add it into the arry ---
		i = 0
		while i < count
			track = read_track(a_file, i)
			tracks << track
			i += 1
		end
		# --- Return the tracks array ---
		return tracks
	end

	# Read a single album
	def read_album(a_file, idx)
		title = a_file.gets.chomp
		year = a_file.gets.chomp.to_i
		artist = a_file.gets.chomp
		# --- Dimension of an album's artwork ---
		if idx % 2 == 0
			leftX = 30
		else
			leftX = 250
		end
		topY = 190 * (idx / 2) + 30 + 20 * (idx/2)
		artwork = ArtWork.new(a_file.gets.chomp, leftX, topY)
		# -------------------------------------
		tracks = read_tracks(a_file)
		album = Album.new(title, year, artist, artwork, tracks)
		return album
	end

	# Read all albums
	def read_albums()
		a_file = File.new("input.txt", "r")
		count = a_file.gets.chomp.to_i
		albums = Array.new()

		i = 0
		while i < count
			album = read_album(a_file, i)
			albums << album
			i += 1
	  	end

		a_file.close()
		return albums
	end

	def display_title(album,x,y,idx)
		@track_font.draw("#{idx+1}. #{album.title} - #{album.year}",x,y,ZOrder::PLAYER)
		gap = 30
		@track_font.draw("Artist: #{album.artist}",x,y+gap,ZOrder::PLAYER)
	end

	def display_titles(albums)
		idx = 0
		x = 500
		while idx < albums.length
			y = 70*idx +30
			display_title(albums[idx],x,y,idx)
			idx +=1
		end
	end

	# Draw albums' artworks
	def draw_albums(albums)
		albums.each do |album|
			album.artwork.bmp.draw(album.artwork.dim.leftX, album.artwork.dim.topY , z = ZOrder::PLAYER)
		end
	end

	# Draw tracks' titles of a given album
	def draw_tracks(album)
		album.tracks.each do |track|
			display_track(track)
		end
	end

	# Draw indicator of the current playing song
	def draw_current_playing(idx, album)
		draw_rect(album.tracks[idx].dim.leftX - 10, album.tracks[idx].dim.topY, 5, @track_font.height(), Gosu::Color::RED, z = ZOrder::PLAYER)
	end

	# Detects if a 'mouse sensitive' area has been clicked on
	# i.e either an album or a track. returns true or false
	def area_clicked(leftX, topY, rightX, bottomY)
		if mouse_x > leftX && mouse_x < rightX && mouse_y > topY && mouse_y < bottomY
			return true
		end
		return false
	end

	# Takes a String title and an Integer ypos
	# You may want to use the following:
	def display_track(track)
		@track_font.draw(track.name, X_LOCATION, track.dim.topY, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
	end


	# Takes a track index and an Album and plays the Track from the Album
	def playTrack(track, album)
		@song = Gosu::Song.new(album.tracks[track].location)
		@song.play(false)
	end

	# Draw a coloured background using TOP_COLOR and BOTTOM_COLOR
	def draw_background()
		draw_quad(0,0, TOP_COLOR, 0, SCREEN_H, TOP_COLOR, SCREEN_W, 0, BOTTOM_COLOR, SCREEN_W, SCREEN_H, BOTTOM_COLOR, z = ZOrder::BACKGROUND)
	end

	# Not used? Everything depends on mouse actions.
	def update
		# If a new album has just been seleted, and no album was selected before -> start the first song of that album
		if @album_playing >= 0 && @song == nil
			@track_playing = 0
			playTrack(0, @albums[@album_playing])
		end
		
		# If an album has been selecting, play all songs in turn
		if @album_playing >= 0 && @song != nil && (not @song.playing?)
			@track_playing = (@track_playing + 1) % @albums[@album_playing].tracks.length()
			playTrack(@track_playing, @albums[@album_playing])
		end
	end

	# Draws the album images and the track list for the selected album
	def draw
		draw_menu_button()
		draw_background()
		draw_albums(@albums)
		case @scene
		when :start 
			display_titles(@albums)
			draw_sort_button()
		when :track
			
			# If an album is selected => display its tracks
			if @album_playing >= 0
				draw_tracks(@albums[@album_playing])
				draw_current_playing(@track_playing, @albums[@album_playing])
			end
		end
	end

 	def needs_cursor?; true; end

	def draw_menu_button
		leftX = 700
		topY = 500
		rightX = 800
		botY = 550
		@menu_button = Dimension.new(leftX,topY,rightX,botY)
		color = Gosu::Color::BLACK
		draw_quad(leftX,topY,color,rightX,topY,color,leftX,botY,color,rightX,botY,color,ZOrder::PLAYER)
		draw_content(@menu_button,"Menu")
	end

	def draw_sort_button
		leftX = 550
		topY = 500
		rightX = 650
		botY = 550
		@sort_button = Dimension.new(leftX,topY,rightX,botY)
		color = Gosu::Color::BLACK
		draw_quad(leftX,topY,color,rightX,topY,color,leftX,botY,color,rightX,botY,color,ZOrder::PLAYER)
		draw_content(@sort_button,"Sort")
	end

	def draw_content(button,content)
		font = Gosu::Font.new(30)
		x = button.leftX + font.text_width(content)/4
		y = button.topY + 10
		font.draw(content,x,y,1,1)
	end

	def sort_albums_by_year(albums,choice)
		case @sort_queues[choice]
		when :ascending_year
			i = 1
			while i < albums.length
				key = albums[i]
				j = i -1
				while j >= 0 && albums[j].year < key.year
					albums[j+1] = albums[j]
					j = j -1
				end
				albums[j+1] = key
				i+=1
			end
		when :descending_year
			i = 1
			while i < albums.length
				key = albums[i]
				j = i -1
				while j >= 0 && albums[j].year > key.year
					albums[j+1] = albums[j]
					j = j -1
				end
				albums[j+1] = key
				i+=1
			end
		when :artist
			i = 1
			while i < albums.length
				key = albums[i]
				j = i -1
				while j >= 0 && albums[j].artist > key.artist
					albums[j+1] = albums[j]
					j = j -1
				end
				albums[j+1] = key
				i+=1
			end
		end
	end

	def button_down(id)
		case id
	    when Gosu::MsLeft
				if area_clicked(@menu_button.leftX,@menu_button.topY,@menu_button.rightX,@menu_button.bottomY)
					@scene = :start
					if @song != nil
						@song = nil
						@album_playing = -1
					end
				end

				if @scene ==:start
					if area_clicked(@sort_button.leftX,@sort_button.topY,@sort_button.rightX,@sort_button.bottomY)
						sort_albums_by_year(@albums,@sort_choice)
						sleep 0.1
						@sort_choice += 1
						if @sort_choice >= @sort_queues.length
							@sort_choice = 0
						end
					end
				end

				if @scene == :track
	    	# If an album has been selected
					if @album_playing >= 0
						# --- Check which track was clicked on ---
						for i in 0..@albums[@album_playing].tracks.length() - 1
							if area_clicked(@albums[@album_playing].tracks[i].dim.leftX, @albums[@album_playing].tracks[i].dim.topY, @albums[@album_playing].tracks[i].dim.rightX, @albums[@album_playing].tracks[i].dim.bottomY)
								playTrack(i, @albums[@album_playing])
								@track_playing = i
								break
							end
						end
					end
				end

				# --- Check which album was clicked on ---
				for i in 0..@albums.length() - 1
					if area_clicked(@albums[i].artwork.dim.leftX, @albums[i].artwork.dim.topY, @albums[i].artwork.dim.rightX, @albums[i].artwork.dim.bottomY)
						@album_playing = i
						@song = nil
						@scene = :track
						break
					end
				end
	    end
	end

end

# Show is a method that loops through update and draw
MusicPlayerMain.new.show if __FILE__ == $0