require 'json'
require 'date'

class Car
  attr_reader :id, :price_per_day, :price_per_km

  def initialize(params)
    @id = params["id"]
    @price_per_day = params["price_per_day"]
    @price_per_km = params["price_per_km"]
  end
end

class Rental
  attr_reader :id, :car_id, :start_date, :end_date, :distance

  def initialize(params)
    @id = params["id"]
    @car_id = params["car_id"]
    @start_date = Date.parse(params["start_date"])
    @end_date = Date.parse(params["end_date"])
    @distance = params["distance"]
  end

  def get_price(cars_array)
    car = cars_array.find { |car| car.id == @car_id }
    #on the line below we calculate duration of rental but we need to add 1 to the count to account for full days
    duration = @end_date - @start_date + 1
    duration_price = duration * car.price_per_day
    distance_price = @distance * car.price_per_km
    total = duration_price + distance_price
  end
end

def level_one(file)
  f = File.read(file)
  data = JSON.parse(f)

  #Define array with all rentals instances
  rentals = data["rentals"].map { |rental| Rental.new(rental) }
  #Define array with all cars instances
  cars = data["cars"].map { |car| Car.new(car) }

  #initiate output
  output = {
    "rentals" => []
  }
  #fill output with relevant data
  rentals.each do |rental|
    output["rentals"].push({id: rental.id, price: rental.get_price(cars).to_i})
  end

  File.open("output.json","w") do |f|
    f.write(JSON.pretty_generate(output))
  end
end

level_one("data.json")
