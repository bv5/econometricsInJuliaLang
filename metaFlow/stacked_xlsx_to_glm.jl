# read the xlsx with low counts and feed that into the glm 
using CSV
using GLM
using XLSX
using Logging
using DataFrames
using Statistics
using LinearAlgebra
using Distributions
using DataStructures
#= NOTE: 
1) The input xlsx needs to be in a properly formatted fashion i.e remove all the empty rows inbetween product codes
2) Move all the product code groupings to a single area with an empty row inbetween each. This is applicable to 1st & 3rd column.
=# 
# we need to retain the insertion order which reflects the input xlsx rows
glm_ols_dict = OrderedDict()
# Please change the following three vars BEFORE you run the script
product_grouping = "FB"
product_year = "2019"
# make sure this path actually exists, because we read the pq CSVs from this path
product_code_csv_folder = "/Users/dm/Downloads/andrade_downloads/less_pq_data/FB_2019/results_CSVs/"

# these just strings that would be used in the find_glm function output
julia_command = "lm(@formula(log(q) ~ p)"
julia_glm = ":(log(q)) ~ 1 + p"

function find_glm(pq_data)
    try
        numOfObservations = size(pq_data, 1)
        if numOfObservations < 2
            @error "too few rows to find GLM"
            return []
        end
        ols = lm(@formula(log(q) ~ p), pq_data)
        #println("ols_$product_code_$year model  results  \n $ols")
        # get the coefficients
        m=match(r"p\s*(\-?\d+\.?\d+)\s*(\-?\d+\.?\d+)\s*(\-?\d+\.?\d+)"misx, string(ols))
        p_coefficient = m.captures[1]
        stdErr = m.captures[2]
        tValue = m.captures[3]
        r2sqred = r2(ols)
        #println("r2(ols_$product_code_$year) goodness of fit \n $r2_ols_FB105")
        @debug "numofObvs = $numOfObservations p_coefficient = $p_coefficient stdErr = $stdErr t-value = $tValue r2 = $r2sqred"
        return [numOfObservations, julia_command, julia_glm, p_coefficient, stdErr, tValue, r2sqred]
    catch e
        @error "Got the error " e.msg
        return []
    end
end


function process_xlsx(Fname)
    """This helps in processing the input xlsx (the one which has product codes)"""
    source_sheet = nothing
    # this is the results file
    filename = split(basename(Fname), ".")[1]
    #lets create results_CSVs folder 
    dirp = dirname(Fname)
    @info "Reading the xlsx file.."
    xf = XLSX.readxlsx(Fname)
    for shtname in XLSX.sheetnames(xf)
        if lowercase(shtname) in ["source", "sheet 1", "sheet1"]
            @info "Found the sheet and it is named as $shtname"
            source_sheet = xf[shtname]
        end
    end
    # now in a loop, access the columns 5 and 10
    fileindex = 1
    fileindex2 = 3  
    total_rows = size(XLSX.get_dimension(source_sheet))[1]
    @info "Total rows in the xlsx are: $total_rows"
    if total_rows <= 1
        @warn "There are no data rows in this file $filename !!"
        return 
    end
    # this contains all the product code groupings in 1st and 3nd column
    productids = []
    # this contains all the product codes in the 1st column
    afilelist = []
    # this contains the product codes in the 2nd column
    cfilelist = []
    for row in 1:total_rows
        # get the price and qty info
        AFileName = source_sheet[row, fileindex]
        CFileName = source_sheet[row, fileindex2]
        @debug "$row Values $AFileName $CFileName"
        # we need to get the cellstyle for AFiles (if it is empty, we check the CFiles)
        if !ismissing(AFileName) && !ismissing(CFileName)
            @debug "Found value in 1st column " AFileName " and 3rd column " CFileName
            push!(afilelist, AFileName)
            push!(cfilelist, CFileName)
            continue
        elseif !ismissing(AFileName)
            @debug "Found value in 1st column: $AFileName pushing into vector"
            push!(afilelist, AFileName)
        elseif !ismissing(CFileName)
            @debug "Found value in 3rd column: $CFileName pushing into vector"
            push!(cfilelist, CFileName)
        else
            @debug "Found no information on row: $row pushing 1st column and 3rd columns vectors into productids"
            # this is an empty row
            if length(afilelist) > 0
                push!(productids, afilelist)
            end
            if length(cfilelist) > 0
                push!(productids, cfilelist)
            end
            afilelist = []
            cfilelist = []
        end
    end # for ...
    # check for residual data
    if length(afilelist) > 0
        push!(productids, afilelist)
    end
    if length(cfilelist) > 0
        push!(productids, cfilelist)
    end
    return productids
end

if(length(ARGS) == 1 && typeof(ARGS[1]) <: String)
    @info "Got the command line argument as " ARGS[1]
    if(ispath(ARGS[1])) && occursin(r".xlsx$"i, ARGS[1])
        resultsArray = process_xlsx(ARGS[1])
        #println(resultsArray)
        @info "done with processing the xlsx"
        for i in resultsArray
            filename = join(i, "_") * ".csv" 
            println(filename)
            # lets not use any temporary vectors/arrays..lets directly insert the values into dataframe
            df = DataFrame(p = Float64[], q = Int64[])
            # lets read each product code and create a merged code file
            for pc in i
                csvf = product_code_csv_folder * "//results_FB" * string(pc) * "_" * product_year * "_analysis.csv"
                for csvrow in CSV.File(csvf, datarow=2, normalizenames=true )
                    push!(df, (csvrow.p, csvrow.q))
                end
            end
            println("DataFrame is " * string(df))
            results = find_glm(df)
            if length(results) > 0 
                glm_ols_dict[join(i, "_")] = results
            else
                @error "did not get results for the CSV: " string(i)
            end
        end
        open(product_code_csv_folder * "//results_cofficients_" * product_grouping * "_" * product_year * ".csv", "w") do io
            write(io, "product_code,numOfObservations,julia_command,julia_glm,p_coefficient,stdErr,t-value,r-squared\n")
            for k in collect(keys(glm_ols_dict))
                write(io, "$k" * "," * join(map(f->string(f), glm_ols_dict[k]),","))
                write(io,"\n")
            end
        end
        if length(resultsArray) != length(keys(glm_ols_dict))
            @warn "Mismatch in CSVs and results: Actual= " * string(length(resultsArray)) " but got = " * string(length(keys(glm_ols_dict))) * " results."
        end    
    else
        @error "Please enter a valid path leading to the xlsx file"
    end
else
    @error "Please provide the XLSX filepath"
end
