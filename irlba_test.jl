import Random: randn
import LinearAlgebra: mul!, diagm, svd
import CSV
import Test: @test

struct UserData
	A::Matrix{Float64}
end

function matmul(yptr::Ptr{Float64}, trans::Cchar, xptr::Ptr{Float64}, data::UserData)
	m,n = size(data.A)

	if trans == 84
		x = unsafe_wrap(Array, xptr, m)
		y = unsafe_wrap(Array, yptr, n)
		mul!(y, A', x)
	else
		x = unsafe_wrap(Array, xptr, n)
		y = unsafe_wrap(Array, yptr, m)
		mul!(y, A, x)
	end
	nothing
end

function randv(yptr::Ptr{Float64}, n::Cint, data::UserData)
	y = unsafe_wrap(Array, yptr, n)
	y[:] = randn(n)
	nothing
end

function irlba(A, nu, init=nothing)
	m,n = size(A)
	m_b = nu + 7

	if m_b < nu
		m_b = nu + 1
	end

	if m_b > min(m,n)
		m_b = min(m,n)
	end

	V = zeros(n, nu)
	if init === nothing
		init = randn(n)
	end

	U = zeros(m, nu)
	s = zeros(nu)

	SVtol = min(sqrt(eps()), 1e-6)
	restart = 0
	tol = 1e-5
	maxit = 1000

	ccall(("irlba", "./irlba.so"), Cint,
		(Int64, Int64, Int64, Int64, Int64, Int64, Float64, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Cvoid}, Ptr{Cvoid}, Any),
		m, n, nu, m_b, maxit, restart, tol, init, s, U, V,
		@cfunction(randv, Cvoid, (Ptr{Float64}, Cint, Ref{UserData})),
		@cfunction(matmul, Cvoid, (Ptr{Float64}, Cchar, Ptr{Float64}, Ref{UserData})),
		UserData(A))
	U,s,V
end

A = Matrix(CSV.read("tests/A3.csv", header=false))

init = nothing
init = [-0.560476,-0.230177,1.558708,0.070508,0.129288,1.715065,0.460916,-1.265061,-0.686853,-0.445662,1.224082,0.359814,0.400771,0.110683,-0.555841,1.786913,0.497850,-1.966617,0.701356,-0.472791,-1.067824,-0.217975,-1.026004,-0.728891,-0.625039,-1.686693,0.837787,0.153373,-1.138137,1.253815,0.426464,-0.295071,0.895126,0.878133,0.821581,0.688640,0.553918,-0.061912,-0.305963,-0.380471,-0.694707,-0.207917,-1.265396,2.168956,1.207962,-1.123109,-0.402885,-0.466655,0.779965,-0.083369,0.253319,-0.028547,-0.042870,1.368602,-0.225771,1.516471,-1.548753,0.584614,0.123854,0.215942,0.379639,-0.502323,-0.333207,-1.018575,-1.071791,0.303529,0.448210,0.053004,0.922267,2.050085,-0.491031,-2.309169,1.005739,-0.709201,-0.688009,1.025571,-0.284773,-1.220718,0.181303,-0.138891,0.005764,0.385280,-0.370660,0.644377,-0.220487,0.331782,1.096839,0.435181,-0.325932,1.148808,0.993504,0.548397,0.238732,-0.627906,1.360652,-0.600260,2.187333,1.532611,-0.235700,-1.026421,-0.710407,0.256884,-0.246692,-0.347543,-0.951619,-0.045028,-0.784904,-1.667942,-0.380227,0.918997,-0.575347,0.607964,-1.617883,-0.055562,0.519407,0.301153,0.105676,-0.640706,-0.849704,-1.024129,0.117647,-0.947475,-0.490557,-0.256092,1.843862,-0.651950,0.235387,0.077961,-0.961857,-0.071308,1.444551,0.451504,0.041233,-0.422497,-2.053247,1.131337,-1.460640,0.739948,1.909104,-1.443893,0.701784,-0.262197,-1.572144,-1.514668,-1.601536,-0.530907,-1.461756,0.687917,2.100109,-1.287030,0.787739,0.769042,0.332203,-1.008377,-0.119453,-0.280395,0.562990,-0.372439,0.976973,-0.374581,1.052711,-1.049177,-1.260155,3.241040,-0.416858,0.298228,0.636570,-0.483781,0.516862,0.368965,-0.215381,0.065293,-0.034067,2.128452,-0.741336,-1.095996,0.037788,0.310481,0.436523,-0.458365,-1.063326,1.263185,-0.349650,-0.865513,-0.236280,-0.197176,1.109920,0.084737,0.754054,-0.499292,0.214445,-0.324686,0.094584,-0.895363,-1.310802,1.997213,0.600709,-1.251271,-0.611166,-1.185480,2.198810,1.312413,-0.265145,0.543194,-0.414340,-0.476247,-0.788603,-0.594617,1.650907,-0.054028,0.119245,0.243687,1.232476,-0.516064,-0.992507,1.675697,-0.441163,-0.723066,-1.236273,-1.284716,-0.573973,0.617986,1.109848,0.707588,-0.363657,0.059750,-0.704596,-0.717218,0.884650,-1.015593,1.955294,-0.090320,0.214539,-0.738528,-0.574389,-1.317016,-0.182925,0.418982,0.324304,-0.781536,-0.788622,-0.502199,1.496061,-1.137304,-0.179052,1.902362,-0.100975,-1.359841,-0.664769,0.485460,-0.375603,-0.561876,-0.343917,0.090497,1.598509,-0.088565,1.080799,0.630754,-0.113640,-1.532902,-0.521117,-0.489870,0.047154,1.300199,2.293079,1.547581,-0.133151,-1.756527,-0.388780,0.089207,0.845013,0.962528,0.684309,-1.395274,0.849643,-0.446557,0.174803,0.074551,0.428167,0.024675,-1.667475,0.736496,0.386027,-0.265652,0.118145,0.134039,0.221019,1.640846,-0.219050,0.168065,1.168384,1.054181,1.145263,-0.577468,2.002483,0.066701,1.866852,-1.350903,0.020984,1.249915,-0.715242,-0.752689,-0.938539,-1.052513,-0.437160,0.331179,-2.014210,0.211980,1.236675,2.037574,1.301176,0.756775,-1.726730,-0.601507,-0.352046,0.703524,-0.105671,-1.258649,1.684436,0.911391,0.237430,1.218109,-1.338774,0.660820,-0.522912,0.683746,-0.060822,0.632961,1.335518,0.007290,1.017559,-1.188434,-0.721604,1.519218,0.377388,-2.052223,-1.364037,-0.200781,0.865779,-0.101883,0.624187,0.959005,1.671055,0.056017,-0.051982,-1.753237,0.099328,-0.571850,-0.974010,-0.179906,1.014943,-1.992748,-0.427279,0.116637,-0.893208,0.333903,0.411430,-0.033036,-2.465898,2.571458,-0.205299,0.651193,0.273766,1.024673,0.817659,-0.209793,0.378168,-0.945409,0.856923,-0.461038,2.416773,-1.651049,-0.463987,0.825380,0.510133,-0.589481,-0.996781,0.144476,-0.014307,-1.790281,0.034551,0.190230,0.174726,-1.055017,0.476133,1.378570,0.456236,-1.135588,-0.435645,0.346104,-0.647046,-2.157646,0.884251,-0.829478,-0.573560,1.503901,-0.774145,0.845732,-1.260683,-0.354542,-0.073556,-1.168651,-0.634748,-0.028842,0.670696,-1.650547,-0.349754,0.756406,-0.538809,0.227292,0.492229,0.267835,0.653258,-0.122709,-0.413677,-2.643149,-0.092941,0.430285,0.535399,-0.555278,1.779503,0.286424,0.126316,1.272267,-0.718466,-0.450339,2.397452,0.011129,1.633568,-1.438507,-0.190517,0.378424,0.300039,-1.005636,0.019259,-1.077421,0.712703,1.084775,-2.224988,1.235693,-1.241044,0.454769,0.659903,-0.199890,-0.645114,0.165321,0.438819,0.883303,-2.052337,-1.636379,1.430402,1.046629,0.435289,0.715178,0.917175,-2.660923,1.110277,-0.484988,0.230617,-0.295158,0.871965,-0.348472,0.518504,-0.390685,-1.092787,1.210011,0.740900,1.724262,0.065154,1.125003,1.975419,-0.281482,-1.322951,-0.239352,-0.214041,0.151681,1.712305,-0.326144,0.373005,-0.227684,0.020451,0.314058,1.328215,0.121318,0.712842,0.778860,0.914773,-0.574395,1.626881,-0.380957,-0.105784,1.404050,1.294084,-1.089992,-0.873071,-1.358079,0.181847,0.164841,0.364115,0.552158,-0.601893,-0.993699,1.026785,0.751061,-1.509167,-0.095147,-0.895948,-2.070751,0.150120,-0.079212,-0.097369,0.216153]

nu = 20
U,s,V = irlba(A, nu, init)
S = svd(A)
@test s ≈ S.S[1:nu] atol=1e-5

#S_recon = S.U[:,1:nu] * Diagonal(S.S[1:nu]) * S.V[:,1:nu]'
#A_recon = U*Diagonal(s)*V'
#@test S_recon ≈ A_recon atol=2e-6
