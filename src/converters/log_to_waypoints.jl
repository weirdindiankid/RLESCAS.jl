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

# According to file format specified in Matlab script
# written by Mykel Kochenderfer, mykel@stanford.edu
#
# This script converts a log file produced by RLES and converts it to a "waypoints" file
# of the following format.
#
#   WAYPOINTS FILE:
#   The waypoints file contains a set of encounters. Each encounter is
#   defined by a set of waypoints associated with a fixed number of
#   aircraft. The waypoints are positions in space according to a fixed,
#   global coordinate system. All distances are in feet. Time is specified
#   in seconds since the beginning of the encounter. The file is organized
#   as follows:
#
#   [Header]
#   uint32 (number of encounters)
#   uint32 (number of aircraft)
#       [Encounter 1]
#           [Initial positions]
#               [Aircraft 1]
#               double (north position in feet)
#               double (east position in feet)
#               double (altitude in feet)
#               ...
#               [Aircraft n]
#               double (north position in feet)
#               double (east position in feet)
#               double (altitude in feet)
#           [Updates]
#               [Aircraft 1]
#               uint16 (number of updates)
#                   [Update 1]
#                   double (time in seconds)
#                   double (north position in feet)
#                   double (east position in feet)
#                   double (altitude in feet)
#                   ...
#                   [Update m]
#                   double (time in seconds)
#                   double (north position in feet)
#                   double (east position in feet)
#                   double (altitude in feet)
#               ...
#               [Aircraft n]
#                   ...
#       ...
#       [Encounter k]


module Log_To_Waypoints

export log_to_waypoints

using ..DefineSave
using ..SaveHelpers


include("corr_aem_save_scripts.jl")

using JSON
using DataFrames

function log_to_waypoints{T<:AbstractString}(filenames::Vector{T}; 
    outfile::AbstractString="waypoints.dat")

    d = trajLoad(filenames[1]) #use the first one as a reference
    num_aircraft = get_num_aircraft(d)
    num_encounters = length(filenames) #one encounter per log file
    encounters = Array(Dict{String, Array{Float64, 2}}, num_aircraft, num_encounters)

    #encounter i
    for (i, file) in enumerate(filenames)
        d = trajLoad(file)
        #make sure all of them have the same number of aircraft
        @assert num_aircraft == get_num_aircraft(d)

        #aircraft j
        for j = 1:num_aircraft
            encounters[j, i] = Dict{String, Array{Float64, 2}}()
            encounters[j, i]["initial"] = j2w_initial(d, j)
            encounters[j, i]["update"] = j2w_update(d, j)'
        end
    end
    save_waypoints(outfile, encounters, numupdatetype=UInt16)
    encounters
end

function j2w_initial(d::TrajLog, aircraft_number::Int64)
  #d is the loaded encounter
  out = Array(Float64, 1, 3)
  wm = get_log(d, "WorldModel", aircraft_number)

  pos_north     = wm[1, :y] 
  pos_east      = wm[1, :x]
  altitude      = wm[1, :z] 
  out[1, :] = [pos_north, pos_east, altitude]
  out
end

function j2w_update(d::TrajLog, aircraft_number::Int64)
  #d is the loaded encounter,
  wm = get_log(d, "WorldModel", aircraft_number)
  t_end = nrow(wm) 
  out = Array(Float64, t_end-1, 4)
  for t = 2:t_end #ignore init values
    t_         = wm[t, :t]
    pos_north  = wm[t, :y]
    pos_east   = wm[t, :x]
    altitude   = wm[t, :z]
    out[t - 1, :] = Float64[t_, pos_north, pos_east, altitude]
  end
  out
end

function log_to_waypoints(filename::AbstractString)
  log_to_waypoints([filename], outfile = string(getSaveFileRoot(filename), "_waypoints.dat"))
end

end #module
