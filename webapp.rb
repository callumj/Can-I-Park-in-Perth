require "rubygems"
require 'bundler'
require 'json'
Bundler.require(:default)

URL = "http://203.27.5.68/cpp/action/getBayAvailabilities/a"
PARK_LIST = {}
PARK_LIST["inner"] = ["PCEC", "TerraceRoad", "HisMajestys", "ConcertHall"]
PARK_LIST["outer"] = ["StateLibrary", "CulturalCentre", "RoeStreet", "Citiplace"]

class Helper
	include HTTParty::Icebox

	def self.get_data
		cache :store => 'file', :timeout => 60, :location => '/tmp'
		response = HTTParty.get(URL)
	end

	def self.get_spot?(count)
		case
		when count <= 5
			{:color => "white", :message => "No."}
		when count <= 10
			{:color => "#ff0d00", :message => "Unlikely"}
		when count <= 50
			{:color => "#ff6d00", :message => "Hurry"}
		when count <= 100
			{:color => "#ffd300", :message => "Maybe"}
		else
			{:color => "#0090cc", :message => "Yes!"}
		end
	end
end

get %r{/(data[.]json)?} do |json|
	response = Helper.get_data

	total_parks = {}
	total_parks[:inner] = 0
	total_parks[:outer] = 0

	all_parks = {}
	response["response"].each {|park| all_parks[park["systemName"]] = park}

	park_list = {}
	park_list[:inner] = []
	park_list[:outer] = []
	PARK_LIST.each_key do |type|
		PARK_LIST[type].each do |park| 
			t = type.to_sym
			total_parks[t] += all_parks[park]["freeSpaces"].to_i
			park_list[t] <<  {:name => all_parks[park]["displayName"], :available => all_parks[park]["freeSpaces"]}
		end
	end

	@data = {:count => total_parks, :list => park_list, :status => Helper.get_spot?(total_parks[:inner])}

	if json.nil?
		erb :index
	else
		content_type :json
		@data.to_json
	end
end