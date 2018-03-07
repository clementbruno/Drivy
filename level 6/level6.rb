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
        @deductible_reduction = params["deductible_reduction"]

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
        total = (duration_price + distance_price).to_i
    end

    def commission_calc(total_price)
      total_commission = total_price * 0.3
      commission_details = {
        insurance_fee: (total_commission * 0.5).to_i,
        assistance_fee: (@duration * 100).to_i,
        drivy_fee: (total_commission * 0.5 - (@duration * 100)).to_i
      }
      return commission_details
    end

    def get_total_commission(total_price)
        total_commission = (total_price * 0.3).to_i
    end

    def deductible_calc()
        if @deductible_reduction == false
            return 0
        else
            return (@duration * 400).to_i
        end
    end

    def get_driver_amount(cars_array)
      get_price(cars_array) + deductible_calc()
    end

    def get_owner_amount(cars_array)
      get_price(cars_array) - get_total_commission(get_price(cars_array))
    end

    def get_insurance_amount(cars_array)
      commission_calc(get_price(cars_array))[:insurance_fee]
    end

    def get_assistance_amount(cars_array)
      commission_calc(get_price(cars_array))[:assistance_fee]
    end

    def get_drivy_amount(cars_array)
      commission_calc(get_price(cars_array))[:drivy_fee] + deductible_calc()
    end

    def cost_structure(cars_array)
        {
            driver: get_driver_amount(cars_array),
            owner: get_owner_amount(cars_array),
            insurance: get_insurance_amount(cars_array),
            assistance: get_assistance_amount(cars_array),
            drivy: get_drivy_amount(cars_array)
        }
    end
end

def level_six(file)
    f = File.read(file)
    data = JSON.parse(f)

    rentals = data["rentals"].map { |rental| Rental.new(rental) }
    #Define array with all cars instances
    cars = data["cars"].map { |car| Car.new(car) }
    #Define array with all modifications
    modifications = data["rental_modifications"]

    #initiate output
    output = {
        "rental_modifications" => []
    }

    modifications.each do |modification|
        rental_data = data["rentals"].find { |rental| rental['id'] == modification['rental_id'] }
        modified_rental = rental_data.merge(modification)
        #retrieve rental from rentals arrays
        rental = rentals.find { |rental| rental.id == modification['rental_id'] }
        #Make modified_rental an instance of Rental class
        modified_rental = Rental.new(modified_rental) 

        initial_cost = rental.cost_structure(cars)
        modified_cost = modified_rental.cost_structure(cars)
        driver_diff = modified_cost[:driver] - initial_cost[:driver]
        owner_diff = modified_cost[:owner] - initial_cost[:owner]
        insurance_diff = modified_cost[:insurance] - initial_cost[:insurance]
        assistance_diff = modified_cost[:assistance] - initial_cost[:assistance]
        drivy_diff = modified_cost[:drivy] - initial_cost[:drivy]

        output["rental_modifications"].push({
            id: modification["id"],
            rental_id: modification["rental_id"],
            actions: [
                {
                    who: "driver",
                    type: driver_diff > 0 ? "debit" : "credit", 
                    amount: driver_diff.abs
                },
                {
                    who: "owner",
                    type: owner_diff < 0 ? "debit" : "credit", 
                    amount: owner_diff.abs  
                },
                {
                    who: "insurance",
                    type: insurance_diff < 0 ? "debit" : "credit", 
                    amount: insurance_diff.abs  
                },
                {
                    who: "assistance",
                    type: assistance_diff < 0 ? "debit" : "credit", 
                    amount: assistance_diff.abs  
                },
                {
                    who: "drivy",
                    type: drivy_diff < 0 ? "debit" : "credit", 
                    amount: drivy_diff.abs  
                },
            ]
        })
    end

    File.open("output.json","w") do |f|
        f.write(JSON.pretty_generate(output))
    end
end

level_six("data.json")
