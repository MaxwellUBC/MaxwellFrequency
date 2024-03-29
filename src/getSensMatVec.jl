export getSensMatVec

# = ========= The forward sensitivity ===========================

function getSensMatVec(x::Vector,
				   	     sigma::Vector,  # conductivity on fwd mesh
					        param::MaxwellFreqParam)
    # Sens Mat Vec for FV disctretization on OcTreeMesh
    # matv = J*x
	mu   = 4*pi*1e-7
	U    = param.Fields
	w    = param.freq
	P    = param.Obs
	
	Curl = getCurlMatrix(param.Mesh)
	Msig = getEdgeMassMatrix(param.Mesh,vec(sigma))
  Mmu  = getFaceMassMatrix(param.Mesh,fill(1/mu,length(sigma)))
  
  # eliminate hanging edges and faces
	Ne,   = getEdgeConstraints(param.Mesh)
  Nf,Qf = getFaceConstraints(param.Mesh)
  
  Curl = Qf  * Curl * Ne
  Msig = Ne' * Msig * Ne
  Mmu  = Nf' * Mmu  * Nf

	A    = Curl' * Mmu * Curl - (im * w) * Msig
	
	matv = zeros(Complex128,size(P,2),size(U,2))

	for i=1:size(U,2)
		u = U[:,i] 
		dAdm    = getdEdgeMassMatrix(param.Mesh,u)
		z       = -im*w*Ne'*dAdm*x
		z,      = solveMaxFreq(A,z,Msig,param.Mesh,w,param.Ainv,0)
		z       = vec(Ne*z)
		matv[:,i] = -P'*z	
	end
	return vec(matv)
end # function getSensMatVec for FV OcTreeMesh

if hasJOcTree
function getSensMatVec(x::Vector,sigma::Vector,param::MaxwellFreqParam{OcTreeMeshFEM})
    # Sens Mat Vec for FEM disctretization on OcTreeMesh
	mu   = 4*pi*1e-7
	U    = param.Fields
	w    = param.freq
	P    = param.Obs
	
	K,M,Msig = getMatricesFEM(param.Mesh,sigma)
	N        = getEdgeConstraints(param.Mesh)   
	A        = N'*(K/mu - 1im*w*Msig)*N
	
	matv   = zeros(Complex128,size(P,2),size(U,2))
	
	for i=1:size(U,2)
		u = U[:,i] 
		dAdm    = getDiffMassMatrixFEM(param.Mesh,u)
		dAdm    = -im*w*N'*dAdm
		z       = dAdm*x
		z,      = solveMaxFreq(A,z,Msig,param.Mesh,w,param.Ainv,0)
		z       = vec(N*z)
		matv[:,i] = -P'*z	
	end
	return matv
end
end

function getSensMatVec(x::Vector,sigma::Vector,param::MaxwellFreqParamSE)
	if isempty(param.Sens)
		warn("getSensTMatVec: Recomputing data to get sensitvity matrix. This should be avoided.")
		Dc,param = getData(sigma,param)
	end
	return param.Sens*x
end
