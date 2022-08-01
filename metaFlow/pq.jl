using XLSX
using CSV

"""This file reads the two columns in the excel/csv file and creates a CSV with these two columns"""
function generate_results(Fname, variation_threshold=10, minimum_row_count=10)
    price_qty = Dict{Float64, Int64}()
    # applicable to the xlsx mode and not for csv
    source_sheet = nothing
    # this is the results file
    filename = nothing
    dirp = dirname(Fname)
    println("Trying to access the file $Fname")
    # check if the file extension is either csv, xlsx or alien poo
    if occursin(r"\.xlsx$"i, Fname)
        # get the file name without extension
        filename = split(basename(Fname), ".")[1]
        println("Reading the xlsx file..")
        xf = XLSX.readxlsx(Fname)
        # get the sheet named "source/sheet1"
        try
            source_sheet = xf["source"]
        catch LoadError
            println("There is no sheet named 'source' trying 'Sheet1' as the sheet name")
            try
                source_sheet = xf["Sheet1"]
            catch LoadError
                println("There is no sheet named 'Sheet1'..bad hair day I guess. Exiting now")
                exit()
            end
        end
        # now in a loop, access the columns 5 and 10
        row = 2
        price_col = 5
        qty_col = 10  
        while true
            #prinln("Source sheet is " * source_sheet)
            if ismissing(source_sheet[row, price_col])
                println("No more rows to process..")
                break
            else
                # println("reading..")
                # get the price and qty info
                price = source_sheet[row, price_col]
                qty = source_sheet[row, qty_col]
                # check if the price is a valid numeric type
                if typeof(price) <: Int64 || typeof(price) <: Float64
                    # get the price variation
                    # check if we've seen this price earlier, if yes, simply sum the qty
                    if haskey(price_qty, price)
                        price_qty[price] += qty
                        true
                    else
                        price_qty[price] = qty
                        true
                    end
                else
                    println("row $row does not have valid price info..skipping")
                end
            end # if source_sheet...
            row += 1
        end # while ...
    elseif occursin(r"\.csv$"i, Fname)
        # the fifth column in the CSV could be named either Unit Price or YTD Unit Price
        isUnitPrice = false
        # get the file name without extension
        filename = split(basename(Fname), ".")[1]
        # now in a loop, access the columns 5 and 10
        println("Reading the csv file...")
        fl = CSV.File(Fname, normalizenames=true)
        if string(propertynames(fl)[5]) == "Unit_Price"
            isUnitPrice = true
        end
        # remove the reference to the csv to free memory..blah!
        fl = nothing
        for csvrow in CSV.File(Fname, datarow=2, normalizenames=true)
            price = nothing
            # if the unit price column does not exist then we use YTD unit price
            if isUnitPrice
                price = csvrow.Unit_Price
            else
                price = csvrow.YTD_Unit_Price
            end
            qty = csvrow.Units
            if ismissing(price)
                break
            end
            if typeof(price) <: Int64 || typeof(price) <: Float64
                # getthe price variation
                if haskey(price_qty, price)
                    price_qty[price] += qty
                    true
                else
                    price_qty[price] = qty
                    true
                end
            else
                println("row $csvrow does not have valid price info..skipping")
            end
        end
    else
        println("Error: This isn't Christmas and am not Santa either..can handle only csv/xlsx")
        exit()
    end
    # lets print the dictionary and also write the results to the file
    open("$dirp//results_" * "$filename" * ".csv", "w") do io
        write(io, "p, q\n")
        for temp in sort(collect(keys(price_qty)))
            println("$temp => " * string(price_qty[temp]))
            write(io, "$temp, " * string(price_qty[temp]) * "\n")
        end
    end
end

# check if the excel/csv file (along with the path is given) or if a folder is given
if length(ARGS) >= 1
    thresholdVariation = 10
    minimumRows = 10
    # if length of ARGS is 1, put 10 in ARGS[2] and ARGS[3]
    try
        if !ismissing(ARGS[2])
            thresholdVariation = ARGS[2]
        end
    catch BoundsError
        println("Taking default value of 10 for threshold variation")
    end
    try
        if !ismissing(ARGS[3])
            minimumRows = ARGS[3]
        end
    catch BoundsError
        println("Taking default value of 10 for minimum rows")
    end
    # check if ARGS[1] is file or folder
    if isdir(ARGS[1])
        # lets read the directory and send the file to the generate_results 
        # one by one, while reading the files, we ignore files starting with 'results_' 
        # as they are created by our script
        files_list = readdir(ARGS[1])
        for fname in files_list
            if occursin(r"^results_"i, fname) || occursin(r"^\.", fname)
                println("$fname seems to be results file generated by this script or some alien artifact..ignoring it")
                continue
            else
                # we are interested in files and not folders
                if !isdir(ARGS[1] * "//$fname")
                    generate_results(ARGS[1] * "//$fname", thresholdVariation, minimumRows)
                else
                    println(ARGS[1] * "//$fname is a folder..ignoring")
                end
            end
        end
    else
        println("Given argument is a file and not a folder")
        generate_results(ARGS[1], thresholdVariation, minimumRows)
    end
else
    println("\n" * "=" ^ 80 * """
    \nPlease run the program like this:\n\njulia pq.jl <excel/csv file or folder containing excel/csv files> <variation threshold> <minimum number of rows to be present in file>\n\nNote: 1st argument is mandatory, the other two arguments are optional""" * "\n" * "=" ^ 80)
    exit()
end