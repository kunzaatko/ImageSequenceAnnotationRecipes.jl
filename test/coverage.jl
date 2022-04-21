using Pkg
Pkg.add("Coverage")
using Coverage
cov_res = process_folder()
haskey(ENV, "COVERALLS_URL") && Coveralls.submit(cov_res)
