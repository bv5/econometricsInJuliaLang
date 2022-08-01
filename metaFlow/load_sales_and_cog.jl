import XLSX
import Dates
using DataFrames
using CSV
using Printf: @sprintf
using Base.Filesystem: mkdir

out_directory = "out_$(Dates.now())"
println("Outputting results to $(out_directory)")

# Create a folder for all the output artifacts.
mkdir(out_directory)

function writeXLSX(df, filename)
    XLSX.writetable("$(out_directory)/$(filename)", collect(DataFrames.eachcol(df)), DataFrames.names(df))
end

# Load the input file.
println("Loading input XLSX...")
input_file = "MUS cookware 2020 1ST QUARTER SALES AND COGS.xlsx"
xf = XLSX.readxlsx(input_file)
println(XLSX.sheetnames(xf))

# Load into a DataFrame.
println("Converting to a DataFrame...")
sheet = xf["MEYER U.S"]
df = DataFrame(XLSX.gettable(sheet, stop_in_row_function = (row)->row[Symbol("Product Name")] === "Total")...)

# "Farberware Other" brand is redundant.
df.Brand = [if b == "Farberware Other" "Farberware" else b end for b in df.Brand]

println("Outputting column-stripped version...")
cols_of_interest = [Symbol("Product Code"), Symbol("Product Name"), Symbol("Brand"), Symbol("Customer Name"), Symbol("Unit Price"), Symbol("Unit Cost"), Symbol("Sales"), Symbol("Costs"), Symbol("Margin"), Symbol("Units")]
writeXLSX(df[:, cols_of_interest], "0_cols_of_interest.xlsx")

println("Summary statistics...")
summary_df = combine(groupby(df, :Brand), :Sales => sum => :Sales, :Units => sum => :Units, nrow => :Transactions, :Margin => sum => :Margin, Symbol("Product Code") => (x->length(unique(x))) => :Unique_Codes)
summary_df.GMP = 100 .* summary_df.Margin ./ summary_df.Sales
summary_df.wt_units = summary_df.Units ./ sum(summary_df.Units)
summary_df.implied_epsilon = -100 ./ summary_df.GMP
writeXLSX(summary_df, "4_brand_group_summary.xlsx")
# println(summary_df)

summary_totals_df = describe(summary_df, :Sum => sum)
summary_totals_df.Sum_human = [if x === nothing nothing else @sprintf("%f", x) end for x in summary_totals_df.Sum]
# println(summary_totals_df)

println("Outputting brand and product code grouped summary results...")
brand_product_code_df = combine(groupby(df, [:Brand, Symbol("Product Code")]), :Sales => sum => :Revenue, nrow => :unique_count, :Units => sum => :unit_count)
sort!(brand_product_code_df, [:Brand, :Revenue], rev = (false, true))
writeXLSX(brand_product_code_df, "1_brand_product_code_df.xlsx")

println("Outputting brand grouped results...")
for (key, brand_df) in pairs(groupby(brand_product_code_df, :Brand))
    # Convert this SubDataFrame into a DataFrame so that we can assign columns to it.
    brand_df = DataFrame(brand_df)
    brand_df.cumulative_revenue = cumsum(brand_df.Revenue)
    mkdir("$(out_directory)/$(key.Brand)")
    writeXLSX(brand_df, "$(key.Brand)/brand_analysis.xlsx")
end

println("Outputting brand and product code grouped complete results...")
for (key, pc_df) in pairs(groupby(df[:, cols_of_interest], [:Brand, Symbol("Product Code")]))
    writeXLSX(pc_df, "$(key.Brand)/$(key."Product Code")_analysis.xlsx")
end
