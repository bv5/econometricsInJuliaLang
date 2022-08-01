using CSV
using GLM
using XLSX
using Logging
using DataFrames
using Statistics
using LinearAlgebra
using Distributions
# TODO: fix the issue where user does not give enough cmd line arguments or mixes up the arguments order.
wroteheader = false
julia_command = "lm(@formula(log(q) ~ p)"
julia_glm = ":(log(q)) ~ 1 + p"
logger = ConsoleLogger(stdout, Logging.Info)
global_logger(logger)
# used to display the file number in a folder full of files.
filecounter = 1
"""This file reads the two columns in the excel/csv file and creates a CSV with these two columns"""

function invalid_arguments()
    print("""
    *************************************************************************************
                                        HOW-TO

    julia pq.jl <path to file/folder> <integer> <integer> <true/false> <true/false>

    1) File/Folder Path:                 1st Argument must be a valid path leading to a file or folder.
    2) Threshold Variation:              2nd Argument must be a valid number.
    3) Minimum # Of Rows In Input File:  3rd Argument must be a valid number.
    4) Bunch Prices?:                    4th Argument must be either true/false.
    5) Calculate GLM?:                   5th Argument must be either true/false.

    **************************************************************************************
    """)
    println()
    exit()
end

function find_glm(csvFilename)
    pq_low_data = "//tmp//pq_low_data.txt"
    try
        @info "finding the GLM for $csvFilename"
        pq_data = CSV.read(csvFilename)
        dataf = split(csvFilename, "_")
        product_code = dataf[2]
        year = dataf[3]
        numOfObservations = size(pq_data, 1)
        if numOfObservations <= 2
            open(pq_low_data, "a") do io
                write(io, "$csvFilename , low\n")
            end
            error("too few rows to calculate GLM")
        end
        @debug "going for ols"
        ols = lm(@formula(log(q) ~ p), pq_data)
        #println("ols_$product_code_$year model  results  \n $ols")
        # get the coefficients
        @debug "getting the coefficients.."
        m=match(r"p\s*(\-?\d+\.?\d+)\s*(\-?\d+\.?\d+)\s*(\-?\d+\.?\d+)"misx, string(ols))
        p_coefficient = m.captures[1]
        stdErr = m.captures[2]
        tValue = m.captures[3]
        r2sqred = r2(ols)
        #println("r2(ols_$product_code_$year) goodness of fit \n $r2_ols_FB105")
        @info "numofObvs = $numOfObservations p_coefficient = $p_coefficient stdErr = $stdErr t-value = $tValue r2 = $r2sqred"
        return [numOfObservations, p_coefficient, stdErr, tValue, r2sqred]
    catch e
        @debug "in catch block"
        @error "Got the error " e
        open(pq_low_data, "a") do io
            write(io, "$csvFilename , error\n")
        end
        return []
    end
end

function bart_trunc(num, precis)
    """This function is used to get floats with one or two decimal places"""
    # pad the stringified num with zeros
    if num != 0
        num = string(num) * "00"
    end
    if precis == 2
        @debug "Got num " num
        return parse(Float64, match(r"(\d+\.\d{2})", num).captures[1])
    elseif precis == 1
        @debug "Got 1 precis num " num
        return parse(Float64, match(r"(\d+\.\d)", num).captures[1])
    end
end

function generate_results(Fname, variation_threshold=10, minimum_row_count=10, bunch_prices=false, isGLM=false)
    price_qty = Dict{Float64, Int64}()
    price_occurences = Dict{Float64, Int64}()
    # applicable to the xlsx mode and not for csv
    source_sheet = nothing
    # this is the results file
    filename = split(basename(Fname), ".")[1]
    #lets create results_CSVs folder 
    dirp = dirname(Fname)
    results_CSVs_Folder = dirp * "//" * "results_CSVs"
    resultsCSVFname = results_CSVs_Folder * "//results_" * "$filename" * ".csv"
    try
        if !ispath(results_CSVs_Folder)
            @debug results_CSVs_Folder " path does not exist...trying to create"
            mkdir(results_CSVs_Folder)
        end
    catch Exception
        @error "Unable to create results_CSVs folder..exiting"
        exit()
    end
    println("$filecounter) Trying to access the file $Fname")
    # check if the file extension is either csv, xlsx or alien poo
    if occursin(r"\.xlsx$"i, Fname)
        @info "Reading the xlsx file.."
        xf = XLSX.readxlsx(Fname)
        for shtname in XLSX.sheetnames(xf)
            if lowercase(shtname) in ["source", "sheet 1", "sheet1"]
                @info "Found the sheet and it is named as $shtname"
                source_sheet = xf[shtname]
            end
        end
        # now in a loop, access the columns 5 and 10
        price_col = 5
        qty_col = 10  
        total_rows = size(XLSX.get_dimension(source_sheet))[1]
        @info "Total rows in the xlsx are: $total_rows"
        if total_rows <= 1
            @warn "There are no data rows in this file $filename !!"
            global filecounter += 1
            return 
        end
        for row in 2:total_rows
            # get the price and qty info
            price = source_sheet[row, price_col]
            qty = source_sheet[row, qty_col]
            if price <= 0
                @warn "Found zero/negative price with qty " * string(qty)
                continue
            end
            # check if the price is a valid numeric type
            if typeof(price) <: Int64 || typeof(price) <: Float64
                # get the price variation
                # check if we've seen this price earlier, if yes, simply sum the qty
                if haskey(price_qty, price)
                    price_qty[price] += qty
                    price_occurences[price] +=1
                    true
                else
                    price_qty[price] = qty
                    price_occurences[price] =1
                    true
                end
            else
                @warn "row $row does not have valid price info..skipping"
            end
        end # for ...
    elseif occursin(r"\.csv$"i, Fname)
        # the fifth column in the CSV could be named either Unit Price or YTD Unit Price
        isUnitPrice = false
        # now in a loop, access the columns 5 and 10
        @info "Reading the csv file..."
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
            if ismissing(csvrow.Product_Code)
                break
            end

            if typeof(price) <: Int64 || typeof(price) <: Float64
                if price == 0
                    @warn "Found zero price with qty " * string(qty)
                    continue
                end
                # getthe price variation
                if haskey(price_qty, price)
                    price_qty[price] += qty
                    true
                else
                    price_qty[price] = qty
                    true
                end
            else
                @warn "row $csvrow does not have valid price info..skipping"
            end
        end
    else
        @error "This isn't Christmas and am not Santa either..can handle only csv/xlsx"
        return
    end
    
    # lets print the dictionary and also write the results to the file
    open(resultsCSVFname, "w") do io
        write(io, "p,q\n")        
        if bunch_prices
            # this has the processed results from 1st pass of the csv/xlsx files
            fck = []
            # this array holds the final results
            results = []
            # this array will hold temporary calculations
            tempf = []
            for temp in sort(collect(keys(price_qty)))
                @debug "$temp => "  string(price_qty[temp])
                push!(fck, [temp, price_qty[temp]])
            end
            ## this is the 2nd pass of the values that are present in fck array. 
            # the 1st pass happens on the csv/xlsx file itself
            counter = 1
            while true
                @debug "Pushing " string(fck[1])
                push!(tempf, fck[1])
                deleteat!(fck, 1)
                # if there are more elements in the array we "reduce"
                if length(fck) > 1
                    @debug "in the loop " string(fck)
                    counter = 1
                    for i in fck
                        @debug "considering value " string(i)
                        # get the first element and compare that with the rest of the 
                        # elements in such a way that if it equal to or more than tenths \
                        # then you break out of the inner loop
                        @debug "am here "  string(tempf) " i is " string(i)
                        #println("checking if " * string(bart_trunc(tempf[1][1], 1)) * " i5s with in range " * string(bart_trunc(i[1][1], 1)) * " = " * string(bart_trunc(i[1][1], 2) - bart_trunc(tempf[1][1], 2)))
                        if  bart_trunc(i[1][1], 1) == bart_trunc(tempf[1][1], 1)
                            if bart_trunc(i[1][1], 2) - bart_trunc(tempf[1][1], 2) >= 0.1
                                @debug "the difference is higher than 0.1..breaking away from inner loop"
                                break
                            else
                                @debug "the difference is less than 0.1..checking the next number"
                                push!(tempf, i)
                                counter += 1
                            end
                        else
                            @debug "the difference is higher than 0.1..breaking away from inner loop"
                            break
                        end
                    end
                    for i in 1:counter-1
                        deleteat!(fck, 1)
                    end
                end
                # get the WAP and push the result in to results array
                sum_pq = 0
                sum_q = 0
                for i in tempf
                    sum_pq += i[1] * i[2]
                    sum_q += i[2]
                end
                wap  = sum_pq/sum_q
                write(io, string(wap) * "," * string(sum_q) * "\n")
                @debug "current array " string(tempf) string(wap) " => " string(sum_q)  "\n"  "*" ^ 50
                push!(results, [wap, sum_q])
                # empty temp for another round of "reducing"
                tempf = []
                if length(fck) == 0
                    @warn "No more values in array to be reduced..."
                    break
                end
            end
        else
            for temp in sort(collect(keys(price_qty)))
                @debug "$temp => " string(price_qty[temp])
                write(io, "$temp, " * string(price_qty[temp]) * "\n")
            end
        end
    end
    
    if isGLM
        resultsArray = find_glm(resultsCSVFname)
        if length(resultsArray) != 0
            # lets get the product code 
            m = match(r"[A-Za-z]{2,}(\d{3,})_", filename)
            product_code = m.captures[1] 
            # the following is a special case to handle LL sub brand.            
            # m = match(r"^([A-Za-z]{2})(.*\d{3,})_", filename)
            # product_code = split(m.captures[2], "_")[1]

            open("$results_CSVs_Folder//results_cofficients.csv", "a") do io
                println("writing the cofficients...")
                if !wroteheader
                    write(io, "\"source_filename\",\"product code\",\"n\",\"julia_command\",\"julia_GLM_model\",\"p_coefficient\",\"StdError\",\"t-value\",\"r-squared\"\n")
                    global wroteheader = true
                end
            write(io, "\"$filename\",\"$product_code\",\"" * string(resultsArray[1]) * "\",\"$julia_command\",\"$julia_glm\",\"" * string(resultsArray[2]) * "\",\"" * string(resultsArray[3]) * "\",\"" * string(resultsArray[4]) * "\",\"" * string(resultsArray[5]) * "\"\n")
            end
        end
    end
    println("\n" * "^" ^ 80 * "\n" * "\nFinished reading and processing the file $filename\n" * "^" ^ 80 * "\n\n")
    global filecounter += 1
end

# check if the excel/csv file (along with the path is given) or if a folder is given
if length(ARGS) >= 1
    thresholdVariation = 10
    minimumRows = 10
    bunch_prices = false
    isGLM = false
    #lets do some error checking
    #first argument is a string and it should be a valid path
    try
        if !(typeof(ARGS[1]) <: String && ispath(ARGS[1]))
            @error ARGS[1] " is not a valid path"
        end
        if !ismissing(ARGS[2])
            global thresholdVariation = parse(Int64, ARGS[2])
        end
        if !ismissing(ARGS[3])
            global minimumRows = parse(Int64, ARGS[3])
        end
        if !ismissing(ARGS[4]) && typeof(ARGS[4]) <: String
            if lowercase(ARGS[4]) == "true"
                global bunch_prices = true
            else
                global bunch_prices = false
            end
        end
        if !ismissing(ARGS[5]) && typeof(ARGS[5]) <: String
            if lowercase(ARGS[5]) == "true"
                global isGLM = true
            else
                global isGLM = false
            end
        end
     catch Exception
        invalid_arguments()
    end
    @info "Got the command line arguments as thresholdVariation = $thresholdVariation minimumRows = $minimumRows bunch_prices = $bunch_prices isGLM = $isGLM"
    # check if ARGS[1] is file or folder
    if isdir(ARGS[1])
        # lets read the directory and send the file to the generate_results 
        # one by one, while reading the files, we ignore files starting with 'results_' 
        # as they are created by our script
        files_list = readdir(ARGS[1])
        for fname in files_list
            if occursin(r"^results_"i, fname) || occursin(r"^\.", fname)
                @warn "$fname seems to be results file generated by this script or some alien artifact..ignoring it"
                continue
            else
                # we are interested in files and not folders
                if !isdir(ARGS[1] * "//$fname")
                    generate_results(ARGS[1] * "//$fname", thresholdVariation, minimumRows, bunch_prices, isGLM)
                else
                    println(ARGS[1] * "//$fname is a folder..ignoring")
                end
            end
        end
    else
        println("Given argument is a file and not a folder")
        generate_results(ARGS[1], thresholdVariation, minimumRows, bunch_prices, isGLM)
    end
else
    invalid_arguments()
end
