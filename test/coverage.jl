using Pkg
Pkg.add("Coverage")
using Coverage
cov_res = process_folder()
print(haskey(ENV, "COVERALLS_URL"))
Coveralls.submit(cov_res)
