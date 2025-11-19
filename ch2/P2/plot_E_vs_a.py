import numpy as np
import matplotlib.pyplot as plt

# Load data: columns -> a(Å), E_total(Ry), V(Å³/atom)
a, E_Ry, V = np.loadtxt('E_vs_a_hf.dat', unpack=True)

# Convert energy to eV (optional, for readability)
E_eV = E_Ry * 13.605693122994

# Shift energy so the minimum is at 0 eV (optional)
E_shift = E_eV - E_eV.min()

# Plot
plt.figure(figsize=(6,4))
plt.plot(a, E_shift, 'o-', color='navy', lw=1.5, ms=6)

plt.xlabel('Lattice parameter a (Å)', fontsize=12)
plt.ylabel('Total energy (eV) [shifted]', fontsize=12)
plt.title('Hf hcp: Total Energy vs Lattice Constant a', fontsize=13)
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()

