# *****************************************************************************
# Written by Ritchie Lee, ritchie.lee@sv.cmu.edu
# *****************************************************************************
# Copyright ã 2015, United States Government, as represented by the
# Administrator of the National Aeronautics and Space Administration. All
# rights reserved.  The Reinforcement Learning Encounter Simulator (RLES)
# platform is licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You
# may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable
# law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.
# _____________________________________________________________________________
# Reinforcement Learning Encounter Simulator (RLES) includes the following
# third party software. The SISLES.jl package is licensed under the MIT Expat
# License: Copyright (c) 2014: Youngjun Kim.
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED
# "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# *****************************************************************************

"""
Trajplot jsons into two folders depending on an indicator vector.
"""
module SortPlotsToFolders

export sort_plots_to_folders
export script_APL042017_10K_cassim

using DataFrames
using RLESUtils, PGFPlotUtils
using RLESCAS
include_visualize()

const APL042017_10K_CASSIM_META = Pkg.dir("Datasets/data/APL042017_10K_cassim/_META.csv.gz")

function sort_plots_to_folders{T<:AbstractString}(files::Vector{T}, 
    indicator::Vector{Bool}, true_folder::AbstractString, 
    false_folder::AbstractString; verbose::Bool=true,
    format::Symbol=:TEXPDF)

    @assert length(files) == length(indicator)    
    mkpath(true_folder)
    mkpath(false_folder)
    for i = 1:length(files)
        verbose && println("file $i of $(length(files))")
        f = files[i]
        b = indicator[i]
        folder = b ? true_folder : false_folder
        d = trajLoad(f)
        outfileroot = joinpath(folder, split(basename(f), ".")[1])
        trajPlot(outfileroot, d; format=format)
    end
end

function script_APL042017_10K_cassim(basefolder::AbstractString="./";
    format::AbstractString="PDF")

    D = readtable(APL042017_10K_CASSIM_META)
    encounter_ids = convert(Array, D[:encounter_id])
    files = map(encounter_ids) do id
        f = "trajSaveMCTS_ACASX_GM_" * lpad(id, 5, 0) * ".json.gz"
        joinpath(basefolder, f)
    end
    indicator = convert(Array, D[:nmac])
    true_folder = joinpath(basefolder, "nmac")
    false_folder = joinpath(basefolder, "non-nmac")
    sort_plots_to_folders(files, indicator, true_folder, false_folder;
        format=format)
end

end #module
