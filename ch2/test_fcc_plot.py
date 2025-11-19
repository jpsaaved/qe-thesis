import numpy as np
import matplotlib.pyplot as plt

a, E = np.loadtxt("E_vs_A_fcc.dat", unpack=True)
plt.plot(a, E, 'o-')
plt.xlabel("Lattice constant (Å)")
plt.ylabel("Total energy (Ry)")
plt.show()
