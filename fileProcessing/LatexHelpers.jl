module LatexHelpers
export generateLists, generateSections, generateTables

# this array has all the types of lists
listStyles = ["alphaupper", "alphalower", "number", "romanlower", "romanupper"]
# this array has all the table types
tableTypesList = ["party_intro", "party_sign"]
upperAlpha = collect('A':'Z')
lowerAlpha = collect('a':'z')
numberlist = collect(1:30)
romanLower = ["i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x", "xi", "xii", "xiii", "xiv", "xv", "xvi", "xvii", "xviii", "xix", "xx"]
# this will control the amount of alignment in generating the tables
# this constant control the alignment of the table in the initial page of 
# the document where the parties are introduced in the contract
TABLE_PARTY_ALIGN = "lll"
# this constant will control the alignment of the table in the last page o
#f the document where the parties are going to sign the contract
TABLE_PARTY_SIGN_ALIGN = "llll"
# latex format line
FMT_LINE = "&\t\t\t\t\t\t\t& \\\\"

function _createListIndices(listStyle, lenofarray)
    listindices = []
    if listStyle == "alphalower"
        listindices = lowerAlpha[1:lenofarray]
    elseif listStyle == "alphaupper"
        listindices = upperAlpha[1:lenofarray]
    elseif listStyle == "romanlower"
        listindices = romanLower[1:lenofarray]
    elseif listStyle == "romanupper"
        listindices = map(A->uppercase(A), romanLower[1:lenofarray])
    elseif listStyle == "number"
        listindices = numberlist[1:lenofarray]
    end
    return listindices
end

function generateTables(filePath, tabletype, listElementStyle)
    """this function will help us generate tables, subtables etc"""
    # we need to check if the list style is either null or if it belongs to one of list styles
    if listElementStyle == "" || listElementStyle in listStyles
        if tabletype in tableTypesList
            try
                # ensure the passed in file exists
                PARTY_ONE = "ACME MARKETING COMPANY LTD"
                PARTY_TWO = "ACME CORPORATION U.S"
                PARTY_ONE_COUNTRY = "CAYMAN ISLANDS"
                PARTY_TWO_COUNTRY = "UNITED STATES OF AMERICA"
                PARTY_ONE_ADDRESS = "456 Main Street, Room 123, Cayman Island 1703, Cayman"
                PARTY_TWO_ADDRESS = "111 Plaza Ln, Los Angeles, CA 90045, U.S.A."
                PARTY_ONE_TITLE = "COMPANY"
                PARTY_TWO_TITLE = "DISTRIBUTOR"
                RECITAL_ARRAY = [["The COMPANY will supply the Products to the DISTRIBUTOR."],
                                ["The COMPANY has appointed the DISTRIBUTOR as its distributor of the",
                                "Products in the United States of America and the DISTRIBUTOR has accepted",
                                "that appointment."],
                                ["To this end, the DISTRIBUTOR has been a distributor of the Products for the",
                                "COMPANY."],
                                ["The COMPANY and the DISTRIBUTOR now desire to formally record in writing",
                                "and ratify the terms and conditions of their previously unwritten distribution",
                                "arrangement(s)."]]
                #open("$filePath", "r") do file
                # read the entire file along with the markers in the input file
                # get the PARTY_ONE
                # get the PARTY_TWO
                # get the PARTY_ONE_COUNTRY
                # get the PARTY_TWO_COUNTRY
                # get the PARTY_ONE_ADDRESS
                # get the PARTY_TWO_ADDRESS
                # get the PARTY_ONE_TITLE
                # get the PARTY_TWO_TITLE
                # get the data into RECITAL_ARRAY
                
                #end
                # lets create .tex file with the information that was read in.
                # check the table tabletype
                if tabletype == "party_intro"
                    party_intro = """
                    \\begin{tabular}{$TABLE_PARTY_ALIGN}\n
                    DATE\t\t\t&\t\\multicolumn{2}{l}{[insert effective date]} \\\\
                            $FMT_LINE
                    \\multicolumn{2}{l}{PARTIES}\t\t\t\t\t& \\\\
                            $FMT_LINE
                                &\t$PARTY_ONE,\t\t\t\t\t\t& \\\\ 
                                &\ta company incorporated in the $PARTY_ONE_COUNTRY, & \\\\
                                &\tthe registered office of which is situated at  & \\\\
                                &\t$PARTY_ONE_ADDRESS & \\     
                                &\t(the \\say{\\bold{\\$PARTY_ONE_TITLE}}) & \\\\
                            $FMT_LINE
                                &\t$PARTY_TWO, 
                                &\ta company incorporated in the $PARTY_TWO_COUNTRY & \\\\
                                &\tthe registered office of which is situated at  & \\\\ 
                                &\t$PARTY_TWO_ADDRESS & \\\\
                                &\t(the \\say{\\bold{\\$PARTY_TWO_TITLE}}). & \\\\
                                $FMT_LINE
                            $FMT_LINE
                    \\multicolumn{2}{l}{RECITALS}			& \\\\
                            $FMT_LINE
                    """
                    recital_string = ""
                    listindices = []
                    lenofarray = length(RECITAL_ARRAY)
                    # generate the list indices depending on the number of elements in recital array 
                    listindices = _createListIndices(listElementStyle, lenofarray)
                    counter = 1    
                    for rec_record in RECITAL_ARRAY
                        recital_string = "$recital_string" * string(listindices[counter]) * " .\t\t\t"
                        for rec in rec_record
                            recital_string = "$recital_string" * "&   " * "$rec" * " & \\\\\n\t\t\t"
                        end
                        counter += 1
                        recital_string = "$recital_string" * "$FMT_LINE\n"
                    end
                    party_intro = "$party_intro" * "$recital_string" * "\\end{tabular}"
                    open("party_intro.tex", "w") do io
                        write(io, "$party_intro")
                    end
                    
                else
                            party_sign = """
\\begin{tabular}{$TABLE_PARTY_SIGN_ALIGN}
EXECUTED in\t\t&\t&\tas an Agreement\t\t&\t\t\\\\
\t\t\t\t&\t&\t&\t\t\t\t\t\t\t\\\\
Signed by\t\t&\t)\t&\t&\t\t\t\t\t\t\\\\ 
\t\t\t\t&\t)\t&\t&\t\t\t\t\t\t\\\\
for and on behalf &\t\t)\t&\t&\t\t\t\t\t\\\\
\\bold{$PARTY_ONE}\t&\t)\t&\t&\t\t\t\t\t\t        \\\\
\t\t\t\t&\t)\t&\t&\t\t\t\t\t\t\\\\
were hereunto affixed\t&\t)\t&\t&\t\t\t\t\\\\
\t\t\t\t&\t)\t&\t&\t\t\t\t\t\t\\\\
in the presence of:\t&\t)\t&\t&\t\\rule{60mm}{0.4pt}\t\t\t\t\\\\
\t\t\t\t&\t\t&\t&\t\t\t\t\t\t\\\\
\t\t\t\t&\t\t&\t&\t\t\t\t\t\t\\\\
\t\t\t\t&\t\t&\t&\t\t\t\t\t\t\\\\
\\hrulefill\t\t&\t\t&\t&\t\t\t\t\t\t\\\\
\t\t\t\t&\t\t&\t&\t\t\t\t\t\t\\\\
Witness\t\t\t&\t\t&\t&\t\t\t\t\t\t\\\\
\t\t\t\t&\t&\t&\t\t\t\t\t\t\t\\\\
\t\t\t\t&\t&\t&\t\t\t\t\t\t\t\\\\
\t\t\t\t&\t&\t&\t\t\t\t\t\t\t\\\\
Signed by\t\t&\t)\t&\t&\t\t\t\t\t\t\\\\
\t\t\t\t&\t)\t&\t&\t\t\t\t\t\t\\\\
for and on behalf &\t\t)\t&\t&\t\t\t\t\t\\\\
\\bold{$PARTY_TWO}\t&\t)\t&\t&\t\t\t\\\\
\t\t\t\t&\t)\t&\t&\t\t\t\t\t\t\\\\
were hereunto affixed\t&\t)\t&\t&\t\t\t\t\\\\
\t\t\t\t&\t)\t&\t&\t\t\t\t\t\t\\\\
in the presence of:\t&\t)\t&\t&\t\\hrulefill\t\t\\\\
\t\t\t\t&\t\t&\t&\t\t\t\t\t\t\\\\
\t\t\t\t&\t\t&\t&\t\t\t\t\t\t\\\\
\t\t\t\t&\t\t&\t&\t\t\t\t\t\t\\\\
\\hrulefill\t\t&\t\t&\t&\t\t\t\t\t\t\\\\
\t\t\t\t&\t\t&\t&\t\t\t\t\t\t\\\\
Witness\t\t\t&\t\t&\t&\t\t\t\t\t\t\\\\

\\end{tabular}"""
                    open("party_sign.tex", "w") do io
                        write(io, "$party_sign")
                    end
                end # end of if tabletype == ...
            catch y
                throw(y)
            end # end of try 
        else
            println("Wrong tabletype given")
        end # end of if tabletype in ...
    else
        println("Wrong listtype given")    
    end # end of if listElementNotation in...
end

function generateSections(filePath, topliststyle, subliststyle, subsubliststyle)
    """this function will help us generate sections, subsections etc"""
    sectionString = ""
    input_string = ["this is string 1", ["this is substring 1", "this is substring 2", "this is substring 3", "this is substring 4", "this is substring 5", "this is substring 6","this is substring 7",  "this is substring 8"],
    "this is string 2", 
    "this is string 3"
   ]
   listindices = []
   subListIndices = []
   subSubListIndices = []
    # generate the list indices depending on the number of elements in recital array 
    listindices = _createListIndices(topliststyle, length(input_string))
    #ensure the passed in file exists
    try
        #open("$filePath", "r") do file
        #end
        if topliststyle in listStyles
            counter = 1                
            for rec in input_string
                # we dont have subliststyle, which means we are only one level deep..yay!
                sectionString = sectionString * """\n\\subsection{test}\n\n\\begin{adjustwidth}{1cm}{0pt}\n\n"""
                # is this element an array?
                if typeof(rec) <: Array
                    subListIndices = _createListIndices(subliststyle, length(rec))
                    # we dont have subsubliststyle, which means we are only two levels deep
                    sectionString = sectionString  * """\n
                    \t\\begin{description}\n\n"""
                    counter2 = 1
                    # we've to do this else our counter will have a wrong index
                    counter -= 1
                    for rec2 in rec
                        # is this element an array?
                        if typeof(rec2) <: Array
                            subSubListIndices = _createListIndices(subsubliststyle, length(rec2))
                            sectionString = sectionString * """\n
                            \t\t\\begin{description}\n\n"""
                            counter3 = 1
                            # we've to do this else our counter2 will have a wrong index
                            counter2 -= 1
                            for rec3 in rec2
                                sectionString = sectionString * "\t\t\t\\item[(" * string(subSubListIndices[counter3]) * ")] " * "$rec3" * "\n\n"
                                counter3 += 1
                            end
                            sectionString = sectionString * """
                            \t\t\\end{description}\n\n
                            """                    
                        else
                            listString = sectionString * "\t\t\\item[(" * string(subListIndices[counter2]) * ")] " * "$rec2" * "\n\n"
                        end
                        counter2 += 1
                    end
                    listString = sectionString * """
                    \t\\end{description}\n\n
                    """
                else
                    sectionString = sectionString * "\t\\item[(" * string(listindices[counter]) * ")] " * "$rec" * "\n\n"
                end
                counter += 1
            end
            sectionString = sectionString * """
            \\end{adjustwidth}\n\n
            """
        else
            # if there is no topliststyle, what the heck are we doing here..Dr.D?
        end # end if if topliststyle
        #open("$filePath", "r") do file
        #end
        open("sections.tex", "w") do io
            write(io, "$sectionString")
        end
    catch y
        throw(y)
    end

end

function generateLists(filePath, topliststyle, subliststyle, subsubliststyle)
    """this function will help us generate lists, sublists etc, we go only three levels deep for this generation..anything more is unweildy"""
    # the easier option to check if we have multiple level lists to generate is to check the matrix dimension. If the 
    # input matrix is a single level then we just have to generate to top level list, if the dimension is anything more 
    # we generate the lists accordingly
    listString = ""
    input_string = ["this is string 1", ["this is substring 1", "this is substring 2", "this is substring 3", "this is substring 4", "this is substring 5", "this is substring 6","this is substring 7",  "this is substring 8"],
                    "this is string 2", 
                    "this is string 3", 
                    "this is string 4", 
                    "this is string 5", 
                    "this is string 6", 
                    "this is string 7", 
                    "this is string 8",
                   ]
    listindices = []
    subListIndices = []
    subSubListIndices = []
    # generate the list indices depending on the number of elements in recital array 
    listindices = _createListIndices(topliststyle, length(input_string))
   #ensure the passed in file exists
    try
        if topliststyle in listStyles
            # we dont have subliststyle, which means we are only one level deep..yay!
            listString = """\\begin{description}\n\n"""
            counter = 1                
            for rec in input_string
                # is this element an array?
                if typeof(rec) <: Array
                    subListIndices = _createListIndices(subliststyle, length(rec))
                    # we dont have subsubliststyle, which means we are only two levels deep
                    listString = listString  * """\n
                    \t\\begin{description}\n\n"""
                    counter2 = 1
                    # we've to do this else our counter will have a wrong index
                    counter -= 1
                    for rec2 in rec
                        # is this element an array?
                        if typeof(rec2) <: Array
                            subSubListIndices = _createListIndices(subsubliststyle, length(rec2))
                            listString = listString * """\n
                            \t\t\\begin{description}\n\n"""
                            counter3 = 1
                            # we've to do this else our counter2 will have a wrong index
                            counter2 -= 1
                            for rec3 in rec2
                                listString = listString * "\t\t\t\\item[(" * string(subSubListIndices[counter3]) * ")] " * "$rec3" * "\n\n"
                                counter3 += 1
                            end
                            listString = listString * """
                            \t\t\\end{description}\n\n
                            """                    
                        else
                            listString = listString * "\t\t\\item[(" * string(subListIndices[counter2]) * ")] " * "$rec2" * "\n\n"
                        end
                        counter2 += 1
                    end
                    listString = listString * """
                    \t\\end{description}\n\n
                    """
                else
                    listString = listString * "\t\\item[(" * string(listindices[counter]) * ")] " * "$rec" * "\n\n"
                end
                counter += 1
            end
            listString = listString * """
            \\end{description}\n\n
            """
        else
            # if there is no topliststyle, what the heck are we doing here..Dr.D?
        end # end if if topliststyle
        #open("$filePath", "r") do file
        #end
        open("list.tex", "w") do io
            write(io, "$listString")
        end
    catch y
        throw(y)
    end

end

end
