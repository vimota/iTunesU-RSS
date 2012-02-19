require "rss/maker"
require "FileUtils"

BASE_PATH 	= Dir.home + "/Music/iTunes/iTunes Media/iTunes U"
VERSION 	= "2.0"
BASE_URL	= "http://192.168.0.191/"
BASE_SRV	= "/Library/WebServer/Documents/"

def urlize text
	text.gsub(" ", "-").gsub(",", "_")
end

Dir.glob(BASE_PATH + "/*").each do |folder|
	feed_name = folder.match(/iTunes U\/(.*)/)[1]
	dest	  = urlize(feed_name) + ".xml"

	FileUtils.cp_r(folder, BASE_SRV)
	puts "Copied the directory #{feed_name} and its files into webserver."
	begin
		FileUtils.mv(BASE_SRV + feed_name, BASE_SRV + urlize(feed_name)) #Renames folders
	rescue
		puts "Error renaming folder (may have already been renamed): " + folder
	end

	content = RSS::Maker.make(VERSION) do |m|
		m.channel.title = feed_name
		m.channel.link = "http://www.vimota.me"
		m.channel.description = "iTunes U feed acquired through itunes-rss.rb by Victor Mota"

		Dir.glob(BASE_PATH + "/" + feed_name + "/*").each do |file|
			if file.end_with? ".m4v"
				file_name 	= file.match(/#{feed_name}\/(.*)/)[1]
				link 	  	= BASE_URL + urlize(feed_name) + "/" + urlize(file_name)

				i = m.items.new_item
				i.title = file_name
				i.link = link
				i.guid.content = link 
				i.guid.isPermaLink = true
				i.enclosure.url = link
				i.enclosure.length = File.stat(file).size
				i.enclosure.type = 'video/x-m4v'
				begin
					FileUtils.mv(BASE_SRV + urlize(feed_name) + "/" + file_name, BASE_SRV + urlize(feed_name) + "/" + urlize(file_name))
				rescue
				end
			end
		end
	end

	#writes RSS feed directly to webserver path
	File.open(BASE_SRV + dest,"w") do |f|
		f.write(content)
		puts "Created feed for #{feed_name}."
	end
end
