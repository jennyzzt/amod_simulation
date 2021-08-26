## Packages used
- MATLAB
- YALMIP
- Gurobi

## Dataset used
- https://github.com/bstabler/TransportationNetworks
    - Sioux Falls network 
    - Eastern Massachusetts network

## Data Preprocessing Scripts
- `ReadNetworkData.m`
- `ReadDemandData.m`

<details> <summary>Notes</summary>
Set parameter `dem_scale` in both files to the same value. `dem_scale` scales the demand and edge capacity such that Gurobi does not run into numerical errors when solving the optimisation problem.
</details>

## Simulation Scripts
- `Simulation.m`
- `Simulation_mono.m`
- `FixedPoint.m`

<details> <summary>Notes</summary>
Run `Simulation.m` to find an initial feasible point for multi-operators simulations. Then, run `FixedPoint.m` as a heuristic algorithm to find the general Nash equilibrium.
`Simulation_mono` is used for a single-operator simulation, as the optimisation problem is convex.
</details>

## Analysis Scripts
- `AnalyseNE.m`
- `AnalyseNE_optflows.m`

<details><summary>Notes</summary>
`AnalyseNE.m` uses saved results and compute the necessary metrics. Helper functions to plot graphs are also written in `AnalyseNE.m`.
`Analyse_optflows.m` calculates the optimum flows to serve the satisfied induced demand from a competing or self-maximisng simulation.
Colourmaps used are from https://github.com/DrosteEffect/BrewerMap .

