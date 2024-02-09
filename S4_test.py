# Libraries
import numpy as np
import sys
import time
import matplotlib.pylab as plt
import concurrent.futures
import utils

# importing S4
sys.path.append('/programs/S4/build/lib.linux-x86_64-cpython-39/')
import S4

# building the optical constant database
eps_db_out=utils.generate_eps_db('/ComputationalPhotonics/materials/',ext='*.edb')
eps_files,eps_names,eps_db=eps_db_out['eps_files'],eps_db_out['eps_names'],eps_db_out['eps_db']

# stack material an thicknesses
stack=['e_vacuum','e_au','e_vacuum'];
d_list=[0.0,100.0,0.0];

# incident angles
theta_0=0.0
phi_0=0.0

# wavelengths
v_wl=np.linspace(300,800,1)

# nanohole array r and pitch in nm
nh_p=600
nh_r=100
num=100

# conversion factor from nm to μm
cf=1e-3

# initialize s4
S=S4.New(Lattice=((nh_p*cf,0),(0,nh_p*cf)), NumBasis=num)

# retrieving optical constants at wl from the database
e_list=np.array(utils.db_to_eps(v_wl[0],eps_db,stack))

# set materials
S.SetMaterial('Air',e_list[0])
S.SetMaterial('Au',e_list[1])

# Incident medium
S.AddLayer('Inc',d_list[0]*cf,'Air')

# Nanostructured layer
S.AddLayer('Slab',d_list[1]*cf,'Air')
S.SetRegionCircle('Slab', 'Au', (0.0,0.0), nh_r*cf)

# Substrate
S.AddLayer('Sub',d_list[2]*cf,'Air')

# incident wave + computing options
S.SetExcitationPlanewave((theta_0,phi_0),1.0,0.0)
S.SetOptions(PolarizationDecomposition = True,PolarizationBasis='Jones')


# R and T computation at given wavelength
def f_RT(wl):
    
    # setup new incident wave
    S.SetExcitationPlanewave((theta_0,phi_0),1.0/np.sqrt(2.0),-1.0j/np.sqrt(2.0))
    S.SetFrequency(1.0/(wl*cf))
    
    # update materials
    e_list=np.array(utils.db_to_eps(wl,eps_db,stack))
    S.SetMaterial('Air',e_list[0])
    S.SetMaterial('Au',e_list[1])

    # compute power fluxes
    forw_1,back_1 = S.GetPowerFlux(Layer = 'Inc', zOffset = 0)
    forw_2,back_2 = S.GetPowerFlux(Layer = 'Sub', zOffset = 0)

    # compute transmittance and reflectance
    R = np.abs(back_1/forw_1)
    T = np.abs(forw_2/forw_1)
    
    return R,T

# parallel computation
t = time.time()
print('Started S4 test run.')
with concurrent.futures.ProcessPoolExecutor() as executor:
    v_R,v_T = np.array(list(executor.map(f_RT, v_wl))).T
elapsed = time.time() - t
print('S4 test run took ' + str(round(elapsed,1)) + ' seconds.')