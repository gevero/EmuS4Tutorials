# libraries
import numpy as np
import sys
sys.path.append("/programs/EMUstack/backend/")
import concurrent.futures
import time

# setup emustack path
import paths
paths.backend_path = '/programs/EMUstack/backend/'
paths.data_path = '/programs/EMUstack/backend/data/'
paths.msh_path = '/ComputationalPhotonics/msh/'
paths.template_path ='/programs/EMUstack/backend/fortran/msh/'

# import emustack
import objects
import materials
import plotting
from stack import *

# light parameters
wl_1 = 300
wl_2 = 800
n_wl =1

# Set up light objects
wavelengths = np.linspace(wl_1,wl_2, n_wl)
light_list  = [objects.Light(wl, max_order_PWs = 2,theta=0.0,phi=0.0) for wl in wavelengths]

# nanodisk array r and pitch in nm
nd_r = 100
nd_p = 600
nd_h = 100

# nanostructured layer
NHs = objects.NanoStruct('2D_array', nd_p, 2.0*nd_r, height_nm = nd_h,
    inclusion_a = materials.Au, background = materials.Air, loss = True,
    inc_shape='circle',
    plotting_fields=True,plot_real=1,
    make_mesh_now = True, force_mesh = True, lc_bkg = 0.15, lc2= 2.0, lc3= 2.0,plt_msh=True)

# incident medium
superstrate = objects.ThinFilm(period = nd_p, height_nm = 'semi_inf',
    material = materials.Air, loss = False)

# substrate
substrate   = objects.ThinFilm(period = nd_p, height_nm = 'semi_inf',
    material = materials.Air, loss = False)


# EMUstack Function
def simulate_stack(light):

    # evaluate each layer individually 
    sim_NHs          = NHs.calc_modes(light)
    sim_superstrate  = superstrate.calc_modes(light)
    sim_substrate    = substrate.calc_modes(light)

    # build the stack solution
    stackSub = Stack((sim_substrate, sim_NHs, sim_superstrate))
    stackSub.calc_scat(pol = 'TM')

    return stackSub

# parallel computation
t = time.time()
print('Started EMUstack test run.')
with concurrent.futures.ProcessPoolExecutor() as executor:
    stacks_list = list(executor.map(simulate_stack, light_list))
elapsed = time.time() - t
print('EMUstack test run took ' + str(round(elapsed,1)) + ' seconds.')