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
    attr_reader :id, :car_id, :start_date, :end_date, :distance, :duration

    def initialize(params)
        @id = params["id"]
        @car_id = params["car_id"]
        @start_date = Date.parse(params["start_date"])
        @end_date = Date.parse(params["end_date"])
        @distance = params["distance"]

        #on the line below we calculate duration of rental but we need to add 1 to the count to account for full days
        @duration = @end_date - @start_date + 1
    end

    def get_car(cars_array)
        cars_array.find { |car| car.id == @car_id }
    end

    def discounter()
        days_count = {normal: 0, low_discount: 0, medium_discount: 0, high_discount: 0}
        counter = 0
        while counter < @duration do
            if counter < 1
                days_count[:normal] += 1
                counter += 1
            elsif counter < 4
                days_count[:low_discount] += 1
                counter += 1
            elsif counter < 10
                days_count[:medium_discount] += 1
                counter += 1
            else
                days_count[:high_discount] += 1
                counter += 1
            end
        end
        return days_count
    end

    def get_price(cars_array)
        car = get_car(cars_array)
        days = discounter()
        discount_rates = {normal: 0, low_discount: 0.1, medium_discount: 0.3, high_discount: 0.5}
        duration_price = 0
        days.each do |k, _|
            duration_price += days[k] * car.price_per_day * (1 - discount_rates[k])
        end
        distance_price = @distance * car.price_per_km
        total = duration_price + distance_price
    end
end

def level_two(file)
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

level_two("data.json")
