using CSV
using XLSX
using Formatting
# this boolean controls the "check" of printing the header..did i just confuse you?
wroteheader = false
"""
This file reads the following columns the excel/csv file and creates a CSV.

Recall that the Excel to CSV code project (refer to pq.jl in gitlab.com/bocode/julia.git repo) 
used Excel files as a source and the 5th column in these Excel files is price = p 
and the 10th column is quantity of units = q.

Now be aware that column 6 is cost = c.

1. Weighted average cost = c
Defined as SUMPRODUCT(c, q)/SUM(q) in Excel or I believe 'dot(c, q)/sum(q) in Julia. 
The idea is to multiply c and q for all rows, then add these up -- known as a dot product of 2 vectors c and q. 
Then divide this sum by the sum of q. This is the weighted average c which is weighted by the q units.

2. Sales revenue = sr
Defined as SUM(col 7), or sum the data in column 7 which is Sales, or p*q.

3. Gross margin = gm
Defined as SUM(col 9), or sum the data in column 9 which is Gross margin, or (p - c)*q.

4. Gross margin percentage = gmp
Defined as gm/Sr

5. WAP
Weighted average price SUMPRODUCT(p, q)/SUM(q)

6. SUMq
total number of units as well, so put that on the end as SUMq, which is the sum of column J, the 10th column in the source files.

"""
function generate_results(Fname, isfolder)
    product_code = "" # get this only once per csv/xlsx, each input csv/xlsx deals with one product
    sumprod_cq = 0.0
    sumprod_pq = 0.0
    q_sum = 0.0
    sales_rev = 0.0
    gross_margin = 0.0 
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
        for shtname in XLSX.sheetnames(xf)
            if lowercase(shtname) in ["source", "sheet 1", "sheet1"]
                println("Found the sheet and it is named as $shtname")
                source_sheet = xf[shtname]
            end
        end
        # now in a loop, access the columns 5, 6 and 10
        price_col = 5
        cost_col = 6
        qty_col = 10  
        sales_col = 7
        gross_margin_col = 9
        #get the total number of rows
        total_rows = size(XLSX.get_dimension(source_sheet))[1]
        gotProductCode = false
        for row in 2:total_rows
            if !gotProductCode
                product_code = source_sheet[row, 1]
                gotProductCode = true
            end
            # get the price and qty info
            price = source_sheet[row, price_col]
            cost = source_sheet[row, cost_col]
            qty = source_sheet[row, qty_col]
            sales_rev += source_sheet[row, sales_col]
            gross_margin += source_sheet[row, gross_margin_col]
            # println("actual " * string(round(source_sheet[row, sales_col], sigdigits=)) * " Sales $sales_rev")
            # check if the price is a valid numeric type
            if typeof(cost) <: Int64 || typeof(cost) <: Float64
                cq = cost * qty
                sumprod_cq += cq
                q_sum += qty              
            else
                println("row $row does not have valid cost info..skipping")
            end
            if typeof(price) <: Int64 || typeof(price) <: Float64
                pq = price * qty
                sumprod_pq += pq              
            else
                println("row $row does not have valid cost info..skipping")
            end            
        end # for ...
    elseif occursin(r"\.csv$"i, Fname)
        # the fifth column in the CSV could be named either Unit Price or YTD Unit Price
        isUnitPrice = false
        # get the file name without extension
        filename = split(basename(Fname), ".")[1]
        fl = CSV.File(Fname, normalizenames=true)
        if string(propertynames(fl)[5]) == "Unit_Price"
            isUnitPrice = true
        end
        # remove the reference to the csv to free memory..blah!
        fl = nothing
        # now in a loop, access the columns 5 and 10
        println("Reading the csv file...")
        gotProductCode = false
        for csvrow in CSV.File(Fname, datarow=2, normalizenames=true)
            price = nothing
            # if the unit price column does not exist then we use YTD unit price
            if isUnitPrice
                price = csvrow.Unit_Price
            else
                price = csvrow.YTD_Unit_Price
            end
            # this is BLIND way of breaking away from the loop.
            if ismissing(csvrow.Product_Code)
                break
            end
            if !gotProductCode
                product_code = csvrow.Product_Code
                gotProductCode = true
            end

            cost = csvrow.Unit_Cost
            qty = csvrow.Units
            sales_rev += csvrow.Sales
            gross_margin += csvrow.Margin
            # println("Gorss margin $gross_margin sales_rev $sales_rev")
            if typeof(cost) <: Int64 || typeof(cost) <: Float64
                cq = cost * qty
                sumprod_cq += cq
                q_sum += qty
                # println("Cost $cost Quantity $qty ")
            else
                println("row $csvrow does not have valid cost info..skipping")
            end
            if typeof(price) <: Int64 || typeof(price) <: Float64
                pq = price * qty
                sumprod_pq += pq              
            else
                println("row $row does not have valid cost info..skipping")
            end            
        end
    else
        println("Error: This isn't Christmas and am not Santa either..can handle only csv/xlsx")
        exit()
    end
    # weighted cost average
    wac = sumprod_cq/q_sum
    wap = sumprod_pq/q_sum
    # NOTE!!! change the precision accordingly
    gmp = round(gross_margin/sales_rev, digits=12) * 100
    # check if this is a file or a folder
    if isfolder
        # in the directory mode, we print the header only once..obviously
        open("$dirp//results_cost_gross_margin.csv", "a") do io
          if !wroteheader
            write(io, "File,Product_Code,WAP,WAC,SR,GM,GMP,SUMq\n")
            global wroteheader = true
          end
        # we use format here because we get numbers displayed in scientific notation and i dont think we that..do we Dr.D?
        write(io, "$filename,$product_code," * format(wap) * "," * format(wac) * "," * format(sales_rev) * "," * format(gross_margin) * ",$gmp,$q_sum\n")
        end
    else
        # lets print the dictionary and also write the results to the file
        open("$dirp//results_cost_gross_margin.csv", "w") do io
            write(io, "File,Product_Code,WAP,WAC,SR,GM,GMP,SUMq\n")
            write(io, "$filename,$product_code," * format(wap) * "," *  format(wac) * "," * format(sales_rev) * "," * format(gross_margin) * ",$gmp,$q_sum\n")
        end
    end
    println("\nFinished with $filename...\n")
end

# check if the excel/csv file (along with the path is given) or if a folder is given
if length(ARGS) == 1
    isfolder = false
    # if length of ARGS is 1, put 10 in ARGS[2] and ARGS[3]
    # check if ARGS[1] is file or folder
    if isdir(ARGS[1])
        isfolder = true
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
                    generate_results(ARGS[1] * "//$fname", isfolder)
                else
                    println(ARGS[1] * "//$fname is a folder..ignoring")
                end
            end
        end
    else
        println("Given argument is a file and not a folder")
        generate_results(ARGS[1], isfolder)
    end
else
    println("\n" * "=" ^ 80 * """
    \nPlease run the program like this:\n\njulia costgetter.jl <excel/csv file or folder containing excel/csv files>""" * "\n" * "=" ^ 80)
    exit()
end